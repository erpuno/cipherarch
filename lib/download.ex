defmodule CIPHER.DOWN do
  require Record
  require N2O

  def start(login, pass, msg) do
    spawn(fn ->
      :n2o_pi.start(N2O.pi(module: __MODULE__, table: :cipher, sup: CIPHER,
         state: {"local", login, pass, msg, true, []}, name: msg)) end)
  end

  def proc(:init, N2O.pi(state: {org, login, pass, msg_id, delete, pid}) = pi) do
      bearer = case :application.get_env(:n2o, :jwt_prod, false) do
          false -> :application.get_env(:n2o, :bearer, [])
          true -> CIPHER.auth(login, pass)
      end
      {status,id,body} = CIPHER.download(bearer, msg_id)
      :filelib.ensure_dir("priv/download/")
      case status do
           {_,200,_} -> CIPHER.debug 'DOWNLOAD: ~ts~n', [id]
                        :file.write_file("priv/download/" <> :erlang.list_to_binary(id), body, [:binary,:raw])
                   _ -> res = :jsone.decode body
                        msg = :maps.get "message", res
                        code = :maps.get "code", res
                        CIPHER.error 'DOWNLOAD: id: ~p, code: ~ts, message: ~ts~n', [id,code,msg]
      end
      CIPHER.cancel(msg_id)
      {:ok, N2O.pi(pi, state: {org, login, pass, msg_id, delete, id})}
  end

  def proc(_,pi) do
      {:noreply, pi}
  end

end
