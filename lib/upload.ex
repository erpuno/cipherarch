defmodule CIPHER.UP do
  require Record
  require N2O

  def cancel(doc), do: spawn(fn -> :n2o_pi.stop(:cipher, doc) end)

  def start(login, pass, from, to, doc, _cnt) do

    spawn(fn ->
      case :n2o_pi.start(
        N2O.pi(
          module: __MODULE__,
          table: :cipher,
          sup: CIPHER,
          state: {login, pass, from, to, doc, {0, 0, 0}},
          name: doc)) do
        {:error, x} -> CIPHER.error 'CIPHER ERROR: ~p', [x]
        x -> CIPHER.warning 'CIPHER: ~p', [x]
      end
    end)
  end

  def proc(:init, N2O.pi(state: {login, pass, from, to, doc, mode}) = pi) do

    {:ok, file} = :file.read_file(doc)
    url = 'https://ccs-dev-api.cipher.kiev.ua/ccs/auth-2/token'
    body = :jsone.encode([grant_type: "password", username: login, client_id: "arch-client", password: pass])
    len = :io_lib.format('~p',[:erlang.size(body)])
    file_len = :io_lib.format('~p',[:erlang.size(file)])
    app_json = 'application/json'
    headers = [{'Content-Type',app_json},{'Content-Length', len}]
    {:ok,{status,headers,body}} = :httpc.request(:post, {url, headers, app_json, body}, [{:timeout,10000}], [{:body_format,:binary}])
    res = :jsone.decode body
    bearer = :maps.get "token_type", res
    token = :maps.get "access_token", res
    tok = bearer <> " " <> token |> :erlang.binary_to_list
    url = 'https://archive-api.cipher.com.ua/arch/api/v1/object/1'
    octet = 'application/octet-stream'
    headers = [{'Authorization',tok},{'Content-Type',octet},{'Content-Length', file_len}]
    {:ok,{status,headers,body}} = :httpc.request(:post, {url, headers, octet, file}, [{:timeout,100000}], [{:body_format,:binary}])
    CIPHER.debug 'STATUS: ~p~n', [status]
    cancel(doc)
    {:ok, N2O.pi(pi, state: {login, token, from, to, doc, mode})}
  end

  def proc({:upload, messageSize, pos, count, sessionId, rest} = m,
        N2O.pi(state: {login, pass, _, _, msg_id, _}) = pi) do
    {:noreply, pi}
  end

  def proc(any) do
  end

end
