defmodule BenchRead do
  use Mem, worker_number: 2
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
    ] |> supervise(strategy: :one_for_one)
  end

end

defmodule ReadBench do
  use Benchfella

  setup_all do
    :ets.new(:bench_read, [:set, :public, :named_table, write_concurrency: true])
    BenchRead.Supervisor.start_link

    Enum.each(1..100_000, fn x ->
      BenchRead.set(x, x)
    end)

    Enum.each(1..100_000, fn x ->
      :ets.insert(:bench_read, {x, x})
    end)

    {:ok, self}
  end

  teardown_all _ do
    BenchRead.Supervisor.stop
  end

  bench "bench Mem read" do
    Enum.each(1..100_000, fn x ->
      BenchRead.get(x)
    end)
  end

  bench "bench ETS read" do
    Enum.each(1..100_000, fn x ->
      :ets.lookup(:bench_read, x)
    end)
  end

end
