defmodule CIPHER.UP do
  require Record
  require N2O

  def start(login, pass, from, to, doc, _cnt) do

    spawn(fn ->
      case :n2o_pi.start(
        N2O.pi(
          module: __MODULE__,
          table: :cipher,
          sup: CIPHER,
          state: {login, pass, from, to, doc, []},
          name: doc)) do
        {:error, x} -> CIPHER.error 'CIPHER ERROR: ~p', [x]
        x -> CIPHER.warning 'CIPHER: ~p', [x]
      end
    end)
  end

  def proc(:init, N2O.pi(state: {login, pass, from, to, doc, _}) = pi) do
      bearer = case :application.get_env(:n2o, :jwt_prod, false) do
          false -> :application.get_env(:n2o, :bearer, [])
          true -> CIPHER.auth(login, pass)
      end
      {id,res} = CIPHER.upload(bearer, doc)
      case {id,res} do
           {[],_} -> CIPHER.error 'ERROR: ~p~n', [res]
           {id,_} -> CIPHER.debug 'ID: ~p~n', [id]
                     CIPHER.uploadSignature(bearer,id,doc)
                     CIPHER.publish(bearer,id,doc)
                     CIPHER.metainfo(bearer,id,doc)
      end
      CIPHER.cancel(doc)
      {:ok, N2O.pi(pi, state: {login, pass, from, to, doc, id})}
  end

  def proc({:publish, messageSize, pos, count, sessionId, rest} = m,
        N2O.pi(state: {login, pass, _, _, msg_id, _}) = pi) do

      {:noreply, pi}
  end

  def proc(_,pi) do
      {:noreply, pi}
  end

end
