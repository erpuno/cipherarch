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
           {_,200,_} -> :file.write_file("priv/download/" <> :erlang.list_to_binary(id), body, [:binary,:raw])
                   _ -> :skip
      end
      {status2,id2,body2} = CIPHER.downloadSignature(bearer, msg_id)
      case {status2,body2} do
            {{_,200,_},[]} -> CIPHER.warning 'DOWNLOAD SIGNATURE: empty for ~ts', [id2]
             {{_,200,_},signatures} ->
                        :lists.map(fn res ->
                           sid = :maps.get "id", res
                           sign = :maps.get("signature", res) |> :base64.decode
                           CIPHER.debug 'DOWNLOAD SIGNATURE: ~ts', [sid]
                           :file.write_file("priv/download/" <> :erlang.list_to_binary(id)
                                <> "-" <> sid <> ".p7s", sign, [:binary,:raw])
                          end, signatures)
                   _ -> :skip
      end
      CIPHER.cancel(msg_id)
      {:ok, N2O.pi(pi, state: {org, login, pass, msg_id, delete, id})}
  end

  def proc(_,pi) do
      {:noreply, pi}
  end

end
