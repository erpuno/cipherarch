defmodule CIPHER.DOWN do
  require Record
  require N2O

  def start(login, pass, msg) do
    pi = N2O.pi(module: __MODULE__, timeout: :brutal_kill, restart: :temporary, table: :cipher, sup: CIPHER, state: {"local", login, pass, true, []}, name: msg)
    pid = :n2o_pi.pid(:cipher, msg)
    is_pid(pid) and :erlang.exit(pid, :kill)
    case :n2o_pi.start(pi) do
      {:error, x} -> CIPHER.error 'CIPHER ERROR: ~p', [x]
      x -> CIPHER.warning 'CIPHER: ~p', [x]
    end
    :n2o_pi.send(:n2o_pi.pid(:cipher, msg), {:download, msg})
  end

  def proc(:init, pi), do: {:ok, pi}

  def proc({:download, msg_id}, N2O.pi(state: {_, login, pass, _, _}) = pi) do
    bearer =
      case :application.get_env(:n2o, :jwt_prod, false) do
        false -> :application.get_env(:n2o, :cipher_bearer, [])
        true -> CIPHER.auth(login, pass)
      end
    CIPHER.download(bearer, msg_id) |> savePayload
    CIPHER.downloadSignature(bearer, msg_id) |> saveSignatures
    CIPHER.cancel(msg_id)
    {:stop, :normal, :ok, pi}
  end

  def proc(_,pi) do
      {:noreply, pi}
  end

  def savePayload({status, id, body}) do
      :filelib.ensure_dir("priv/download/")
      case status do
           {_,200,_} ->
                file = "priv/download/" <> :erlang.list_to_binary(id)
                :file.write_file(file, body, [:binary,:raw])
           _ -> :skip
      end
  end

  def saveSignatures({status, id, body}) do
      case {status,body} do
           {{_,200,_},[]} -> CIPHER.warning 'DOWNLOAD SIGNATURE: empty for ~ts', [id]
           {{_,200,_},signatures} ->
                :lists.map(fn res ->
                   sid = :maps.get "id", res
                   sign = :maps.get("signature", res) |> :base64.decode
                   CIPHER.debug 'DOWNLOAD SIGNATURE: ~ts', [sid]
                   file = "priv/download/" <> :erlang.list_to_binary(id) <> ".p7s"
                   :file.write_file(file, sign, [:binary,:raw])
                end, signatures)
           _ -> :skip
      end
  end

end
