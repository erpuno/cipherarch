defmodule CIPHER do
  require Record
  require N2O
  use Application

  def start(_, _) do
    :logger.add_handlers(:n2o)
    app = Supervisor.start_link([], strategy: :one_for_one, name: CIPHER)

    login = :application.get_env(:n2o, :login, "")
    pass = :application.get_env(:n2o, :pass, "")

    :n2o_pi.start(N2O.pi(module: CIPHER, table: :cipher, sup: CIPHER,
           state: {"cipherLink", login, pass, 0}, name: "cipherLink"))
    app
  end

  def send(from, to, doc)  do
    :gen_server.cast(:n2o_pi.pid(:cipher, from), {:send, from, to, doc})
  end

  def proc(:init, pi) do
    {:ok, pi}
  end

  def proc({:send, from, to, doc}, N2O.pi(state: {code, login, pass, cnt}) = pi) do
    CIPHER.UP.start(login, pass, from, to, doc, cnt)
    {:noreply, N2O.pi(pi, state: {code, login, pass, cnt + 1})}
  end

  # helpers

  def error(f, x), do: :logger.error(:io_lib.format('CIPHER ' ++ f, x))
  def warning(f, x), do: :logger.warning(:io_lib.format('CIPHER ' ++ f, x))
  def debug(f, x), do: :logger.debug(:io_lib.format('CIPHER ' ++ f, x))
  def info(f, x), do: :logger.info(:io_lib.format('CIPHER ' ++ f, x))

end
