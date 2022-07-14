defmodule CIPHER.DOWN do
  require Record
  require N2O

  def start(login, pass, msg, delete, pid, org) do
    spawn(fn ->
      :n2o_pi.start(N2O.pi(module: __MODULE__, table: :cipher, sup: CIPHER,
         state: {org, login, pass, msg, delete, pid}, name: msg)) end)
  end

  def proc(:init, N2O.pi(state: {org, login, pass, msg_id, delete, pid}) = pi) do
  end

  def proc({:download, msg_id}, N2O.pi(state: {org, _, _, msg_id, _, _}) = pi) do
    {:noreply, pi}
  end

end
