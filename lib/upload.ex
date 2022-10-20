defmodule CIPHER.UP do
  require Record
  require N2O

  def start(login, pass, from, to, doc, sign) do
    pi = N2O.pi(module: __MODULE__, table: :cipher, sup: CIPHER, state: {login, pass, from}, name: doc)
    case :n2o_pi.start(pi) do
      {:error, x} -> CIPHER.error 'CIPHER ERROR: ~p', [x]
      x -> CIPHER.warning 'CIPHER: ~p', [x]
    end
    :n2o_pi.send(:n2o_pi.pid(:cipher, doc), {:send, to, doc, sign})
  end

  def proc(:init, pi), do: {:ok, pi}

  def proc({:send, _to, doc, sign}, N2O.pi(state: {login, pass, _from}) = pi) do
    bearer =
      case :application.get_env(:n2o, :jwt_prod, false) do
        false -> :application.get_env(:n2o, :cipher_bearer, [])
        true -> CIPHER.auth(login, pass)
      end
    {id,res} = CIPHER.upload(bearer, doc)
    case {id,res} do
      {[],_} -> CIPHER.error 'UPLOAD ERROR: ~p', [res]
      {id,_} -> CIPHER.debug 'UPLOAD ID: ~p', [id]
        sign == true and CIPHER.uploadSignature(bearer,id,doc)
        CIPHER.publish(bearer,id,doc)
        CIPHER.metainfo(bearer,id,doc)
    end
    CIPHER.cancel(doc)
    {:stop, :normal, id, pi}
  end

  def proc(_,pi), do: {:noreply, pi}

end
