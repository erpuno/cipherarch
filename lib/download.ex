defmodule CIPHER.DOWN do
  require Record
  require N2O

  def start(login, pass, msg) do
    spawn(fn ->
      :n2o_pi.start(N2O.pi(module: __MODULE__, table: :cipher, sup: CIPHER,
         state: {"local", login, pass, msg, true, []}, name: msg)) end)
  end

  def proc(:init, N2O.pi(state: {_, login, pass, msg_id, _, _}) = pi) do
      bearer = case :application.get_env(:n2o, :jwt_prod, false) do
          false -> :application.get_env(:n2o, :bearer, [])
          true -> CIPHER.auth(login, pass)
      end
      CIPHER.download(bearer, msg_id) |> savePayload
      CIPHER.downloadSignature(bearer, msg_id) |> saveSignatures
      CIPHER.cancel(msg_id)
      {:ok, pi}
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
                   file = "priv/download/" <> :erlang.list_to_binary(id) <> "-" <> sid <> ".p7s"
                   :file.write_file(file, sign, [:binary,:raw])
                end, signatures)
           _ -> :skip
      end
  end

end
