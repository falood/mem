defmodule BenchWrite do
  use Mem, worker_number: 2
end

defmodule BenchWrite.Persistence do
  use Mem, worker_number: 2, persistence: true
end

defmodule BenchWrite.LRU do
  use Mem, worker_number: 2, maxmemory_size: "100M"
end

defmodule BenchWrite.Persistence.LRU do
  use Mem, worker_number: 2, maxmemory_size: "100M", persistence: true
end

defmodule BenchWrite.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop do
    Supervisor.stop(__MODULE__, :normal)
  end

  def init([]) do
    [ BenchWrite.child_spec(),
      BenchWrite.Persistence.child_spec(),
      BenchWrite.LRU.child_spec(),
      BenchWrite.Persistence.LRU.child_spec(),
    ] |> supervise(strategy: :one_for_one)
  end

end

defmodule WriteBench do
  use Benchfella

  setup_all do
    :ets.new(:bench_write, [:set, :public, :named_table, write_concurrency: true])
    BenchWrite.Supervisor.start_link()
  end

  teardown_all _ do
    BenchWrite.Supervisor.stop()
  end

  bench "bench ETS write", [id: get_id()] do
    :ets.insert(:bench_write, {id, id})
  end

  bench "bench Mem write", [id: get_id()] do
    BenchWrite.set(id, id, 200)
  end

  bench "bench Mem write with Persistence", [id: get_id()] do
    BenchWrite.Persistence.set(id, id)
  end

  bench "bench Mem write with LRU", [id: get_id()] do
    BenchWrite.LRU.set(id, id)
  end

  bench "bench Mem write with Persistence and LRU", [id: get_id()] do
    BenchWrite.Persistence.LRU.set(id, id)
  end

  defp get_id do
    :rand.uniform(100_000)
  end

end
