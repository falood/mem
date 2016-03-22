defmodule M do
  use Mem, worker_number: 5
end

defmodule M.Expiry do
  use Mem, worker_number: 5
end

defmodule M.TTL do
  use Mem,
    worker_number: 5,
    maxmemory_size: 3000,
    maxmemory_strategy: :ttl
end

defmodule M.LRU do
  use Mem,
    worker_number: 5,
    maxmemory_size: 3000,
    maxmemory_strategy: :lru
end

defmodule M.FIFO do
  use Mem,
    worker_number: 5,
    maxmemory_size: 3000,
    maxmemory_strategy: :fifo
end

defmodule M.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    [ M.child_spec,
      M.Expiry.child_spec,
      M.TTL.child_spec,
      M.LRU.child_spec,
      M.FIFO.child_spec,
    ] |> supervise(strategy: :one_for_one)
  end

end

M.Supervisor.start_link

ExUnit.start()
