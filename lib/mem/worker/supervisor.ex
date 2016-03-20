defmodule Mem.Worker.Supervisor do
  use Supervisor

  def start_link(names) do
    Supervisor.start_link(__MODULE__, [], name: names.worker_sup_name)
  end

  def init([]) do
    [ worker(Mem.Worker, [], [restart: :temporary])
    ] |> supervise(strategy: :simple_one_for_one)
  end

end
