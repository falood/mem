defmodule M do
  use Mem,
    worker_number: 5,
    maxmemory_size: 3000,
    maxmemory_strategy: :lru
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
