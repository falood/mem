defmodule BenchRead do
  use Mem, worker_number: 2
end

defmodule BenchRead.Persistence do
  use Mem, worker_number: 2, persistence: true
end

defmodule BenchRead.LRU do
  use Mem, worker_number: 2, maxmemory_size: "100M"
end

defmodule BenchRead.Persistence.LRU do
  use Mem, worker_number: 2, maxmemory_size: "100M", persistence: true
end

defmodule BenchRead.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop do
    Supervisor.stop(__MODULE__, :normal)
  end

  def init([]) do
    [ BenchRead.child_spec,
      BenchRead.Persistence.child_spec,
      BenchRead.LRU.child_spec,
      BenchRead.Persistence.LRU.child_spec,
    ] |> supervise(strategy: :one_for_one)
  end

end

defmodule ReadBench do
  use Benchfella

  setup_all do
    bench_dir = Application.get_env(:mnesia, :dir) |> to_string
    File.rm_rf!(bench_dir)
    File.mkdir_p!(bench_dir)

    :ets.new(:bench_read, [:set, :public, :named_table, write_concurrency: true])
    BenchRead.Supervisor.start_link

    Enum.each(1..100_000, fn x ->
      BenchRead.set(x, x)
      BenchRead.Persistence.set(x, x)
      BenchRead.LRU.set(x, x)
      BenchRead.Persistence.LRU.set(x, x)
      :ets.insert(:bench_read, {x, x})
    end)

    {:ok, self()}
  end

  teardown_all _ do
    BenchRead.Supervisor.stop
  end

  bench "bench ETS read", [id: get_id()] do
    :ets.lookup(:bench_read, id)
  end

  bench "bench Mem read", [id: get_id()] do
    BenchRead.get(id)
  end

  bench "bench Mem read with Persistence", [id: get_id()] do
    BenchRead.Persistence.get(id)
  end

  bench "bench Mem read with LRU", [id: get_id()] do
    BenchRead.LRU.get(id)
  end

  bench "bench Mem read with Persistence and LRU", [id: get_id()]  do
    BenchRead.Persistence.LRU.get(id)
  end

  defp get_id do
    :rand.uniform(100_000)
  end

end
