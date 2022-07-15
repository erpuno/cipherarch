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
      bearer = auth(login, pass)
      {id,res} = upload(bearer, doc)
      case {id,res} do
           {[],_} -> CIPHER.error 'ERROR: ~p~n', [res] ; cancel(doc)
           {id,_} -> CIPHER.debug 'ID: ~p~n', [id] ; publish(id,doc) ; cancel(doc)
      end
      {:ok, N2O.pi(pi, state: {login, pass, from, to, doc, id})}
  end

  def proc({:publish, messageSize, pos, count, sessionId, rest} = m,
        N2O.pi(state: {login, pass, _, _, msg_id, _}) = pi) do

      {:noreply, pi}
  end

  def proc(any) do
  end

  def cancel(doc), do: spawn(fn -> :n2o_pi.stop(:cipher, doc) end)

  def publish(id,doc) do
  end

  def upload(bearer,doc) do
      {:ok, file} = :file.read_file(doc)
      file_len = :io_lib.format('~p',[:erlang.size(file)])
      url = :application.get_env(:n2o, :cipher_upload, [])
      octet = 'application/octet-stream'
      headers = [{'Authorization',bearer},{'Content-Type',octet},{'Content-Length', file_len}]
      {:ok,{status,headers,body}} = :httpc.request(:post, {url, headers, octet, file},
                                                          [{:timeout,100000}], [{:body_format,:binary}])
      CIPHER.debug 'STATUS: ~p~n', [status]
      res = :jsone.decode body
      id = :maps.get "id", res, []
      {id,res}
  end

  def auth(login,pass) do
      url = :application.get_env(:n2o, :cipher_auth, [])
      body = :jsone.encode([grant_type: "password", username: login, client_id: "arch-client", password: pass])
      len = :io_lib.format('~p',[:erlang.size(body)])
      app_json = 'application/json'
      headers = [{'Content-Type',app_json},{'Content-Length', len}]
      {:ok,{status,headers,body}} = :httpc.request(:post, {url, headers, app_json, body},
                                                          [{:timeout,10000}], [{:body_format,:binary}])
      CIPHER.debug 'STATUS: ~p~n', [status]
      res = :jsone.decode body
      bearer = :maps.get "token_type", res
      token = :maps.get "access_token", res
      tok = bearer <> " " <> token |> :erlang.binary_to_list
  end

end
