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
    [ BenchWrite.child_spec,
      BenchWrite.Persistence.child_spec,
      BenchWrite.LRU.child_spec,
      BenchWrite.Persistence.LRU.child_spec,
    ] |> supervise(strategy: :one_for_one)
  end

end

defmodule WriteBench do
  use Benchfella

  setup_all do
    :ets.new(:bench_write, [:set, :public, :named_table, write_concurrency: true])
    BenchWrite.Supervisor.start_link
  end

  teardown_all _ do
    BenchWrite.Supervisor.stop
  end

  bench "bench ETS write" do
    Enum.each(1..100_000, fn x ->
      :ets.insert(:bench_write, {x, x})
    end)
  end

  bench "bench Mem write" do
    Enum.each(1..100_000, fn x ->
      BenchWrite.set(x, x, 200)
    end)
  end

  bench "bench Mem write with Persistence" do
    Enum.each(1..100_000, fn x ->
      BenchWrite.Persistence.set(x, x)
    end)
  end

  bench "bench Mem write with LRU" do
    Enum.each(1..100_000, fn x ->
      BenchWrite.LRU.set(x, x)
    end)
  end

  bench "bench Mem write with Persistence and LRU" do
    Enum.each(1..100_000, fn x ->
      BenchWrite.Persistence.LRU.set(x, x)
    end)
  end

end
