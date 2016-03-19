defmodule BenchWrite do
  use Mem, worker_number: 2
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

  bench "bench Mem write" do
    Enum.each(1..1_000_000, fn x ->
      BenchWrite.set(x, x)
    end)
  end

  bench "bench ETS write" do
    Enum.each(1..1_000_000, fn x ->
      :ets.insert(:bench_write, {x, x})
    end)
  end

end
