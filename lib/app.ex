defmodule CIPHER do
  require Record
  require N2O
  use Application

  def start(_, _) do
      :logger.add_handlers(:n2o)
      app = Supervisor.start_link([], strategy: :one_for_one, name: CIPHER)
      pass = :application.get_env(:n2o, :cipher_pass,  "")
      login = :application.get_env(:n2o, :cipher_login, "")
      :n2o_pi.start(N2O.pi(module: CIPHER, table: :cipher, sup: CIPHER,
              state: {"cipherLink", login, pass, 0}, name: "cipherLink"))
      app
  end

  def send(to, doc, sign \\ true)  do
      :gen_server.call :n2o_pi.pid(:cipher, "cipherLink"), {:send, "cipherLink", to, doc, sign}, 10000
  end

  def down(id, sign \\ true)  do
      :gen_server.call :n2o_pi.pid(:cipher, "cipherLink"), {:download, id, sign}, 10000
  end

  def proc(:init, pi) do
      {:ok, pi}
  end

  def proc({:send, from, to, doc, sign}, N2O.pi(state: {_, login, pass, _}) = pi) do
      res = CIPHER.UP.start(login, pass, from, to, doc, sign)
      {:reply, res, pi}
  end

  def proc({:download, msg_id, sign}, N2O.pi(state: {_, login, pass, _}) = pi) do
      res = CIPHER.DOWN.start(login, pass, msg_id, sign)
      {:reply, res, pi}
  end

  # helpers

  def error(f, x), do: :logger.error(:io_lib.format('CIPHER ' ++ f, x))
  def warning(f, x), do: :logger.warning(:io_lib.format('CIPHER ' ++ f, x))
  def debug(f, x), do: :logger.debug(:io_lib.format('CIPHER ' ++ f, x))
  def info(f, x), do: :logger.info(:io_lib.format('CIPHER ' ++ f, x))

  # REST/JSON API

  def cancel(doc), do: spawn(fn -> :timer.sleep(2000) ; :n2o_pi.stop(:cipher, doc) end)

  def publish(bearer,id,_) do
      url = :application.get_env(:n2o, :cipher_upload, []) ++ id
      headers = [{'Authorization',bearer}]
      {:ok,{status,_headers,body}} = :httpc.request(:put, {url, headers},
                                    [{:timeout,100000}], [{:body_format,:binary}])
      CIPHER.debug 'PUBLISH: ~ts ~p', [id,status]
      body
  end

  def metainfo(bearer,id,doc) do
      author = [firstName: "Максим",
                surname: "Сохацький",
                position: "Провідний інженер",
                department: "Розробки інформаційних систем",
                organization: "ІНФОТЕХ"]

      body = :jsone.encode([fileName: doc, description: "Бінарний файл", ownNumber: "123/20",
                            comment: "Коментар від архіваріуса", authors: [author], outerId: "123/20"])
      url = :application.get_env(:n2o, :cipher_upload, []) ++ id ++ '/metadata'
      app_json = 'application/json'
      headers = [{'Content-Type',app_json},{'Authorization',bearer}]
      {:ok,{status,_headers,body}} = :httpc.request(:put, {url, headers, app_json, body},
                                    [{:timeout,100000}], [{:body_format,:binary}])
      case status do
         {_,200,_} -> CIPHER.debug 'METAINFO: ~ts ~p', [id,status]
           _ -> res = :jsone.decode body
                msg = :maps.get "message", res
                code = :maps.get "code", res
                CIPHER.error 'METAINFO: id: ~ts, code: ~ts, message: ~ts', [id,code,msg]
      end
      body
  end

  def upload(bearer,doc) do
      case :file.read_file(doc) do
         {:error, reason} -> {[],reason}
         {:ok, file} ->
      file_len = :io_lib.format('~p',[:erlang.size(file)])
      url = :application.get_env(:n2o, :cipher_upload, []) ++ '1'
      octet = 'application/octet-stream'
      headers = [{'Authorization',bearer},{'Content-Type',octet},{'Content-Length', file_len}]
      {:ok,{status,_headers,body}} = :httpc.request(:post, {url, headers, octet, file},
                                      [{:timeout,100000}], [{:body_format,:binary}])
      CIPHER.debug 'UPLOAD: ~p ~tp', [status, file_len]
      case :jsone.try_decode body do
        {:ok, res, _} ->
          id = :maps.get("id", res, []) |> :erlang.binary_to_list
          {id,res}
        _ -> {[], []}
      end
      end
  end

  def uploadSignature(bearer,id,doc) do
      case :file.read_file(doc <> ".p7s") do
      {:error, _reason} -> CIPHER.warning 'P7S is not available for ~p ~p.', [id,doc]
      {:ok, file} ->
         url = :application.get_env(:n2o, :cipher_upload, []) ++ id ++ '/signature'
         octet = 'application/octet-stream'
         headers = [{'Authorization',bearer},{'Content-Type',octet}]
         {:ok,{status,_headers,body}} = :httpc.request(:put, {url, headers, octet, file},
                                      [{:timeout,100000}], [{:body_format,:binary}])
         case status do
            {_,200,_} -> CIPHER.debug 'UPLOAD SIGNATURE: ~ts ~p', [id,status]
              _ -> res = :jsone.decode body
                   msg = :maps.get "message", res
                   code = :maps.get "code", res
                   CIPHER.error 'UPLOAD SIGNATURE: id: ~ts, code: ~ts, message: ~ts', [id,code,msg]
         end
         {id,body}
      end
  end

  def download(bearer,id) do
      url = :application.get_env(:n2o, :cipher_upload, []) ++ id ++ '/data'
      headers = [{'Authorization',bearer}]
      case :httpc.request(:get, {url, headers}, [{:timeout,100000}], [{:body_format,:binary}]) do
        {:ok,{status,_,body}} -> CIPHER.debug 'DOWNLOAD ~ts: ~p', [id,status]; {status,id,body}
        {:error,x} -> {:error,id,x}
      end
  end

  def downloadSignature(bearer,id) do
      url = :application.get_env(:n2o, :cipher_upload, []) ++ id ++ '/signature'
      headers = [{'Authorization',bearer}]
      res = :httpc.request(:get, {url, headers},
                           [{:timeout,100000}], [{:body_format,:binary}])
      case res do
        {:ok,{{_,200,_}=s,_,body}} -> CIPHER.debug 'DOWNLOAD SIGNATURE: ~ts ~p', [id,s]; {s,id,:jsone.decode(body)}
        {:ok,{s,_,body}} ->
          res = :jsone.decode body
          msg = :maps.get "message", res
          code = :maps.get "code", res
          CIPHER.error 'DOWNLOAD SIGNATURE: id: ~ts, code: ~ts, message: ~ts', [id,code,msg]
          {s,id,res}
        {:error,x} -> {:error,id,x}
      end
  end

  def auth(login,pass) do
      url = :application.get_env(:n2o, :cipher_auth, [])
      body = :jsone.encode([grant_type: "password", username: login, client_id: "arch-client", password: pass])
      len = :io_lib.format('~p',[:erlang.size(body)])
      app_json = 'application/json'
      headers = [{'Content-Type',app_json},{'Content-Length', len}]
      {:ok,{_status,_headers,body}} = :httpc.request(:post, {url, headers, app_json, body},
                                    [{:timeout,10000}], [{:body_format,:binary}])
      res = :jsone.decode body
      bearer = :maps.get "token_type", res
      CIPHER.debug 'AUTH: ~p', [bearer]
      token = :maps.get "access_token", res
      bearer <> " " <> token |> :erlang.binary_to_list
  end

end
