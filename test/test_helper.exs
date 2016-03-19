defmodule M do
  use Mem
end

defmodule M.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    [ M.child_spec,
    ] |> supervise(strategy: :one_for_one)
  end

end

M.Supervisor.start_link

ExUnit.start()
