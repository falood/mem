defmodule Mem.Supervisor do
  use Supervisor

  def start_link([names, module]) do
    :ets.new(names[:data_ets],   [:set, :public, :named_table])
    :ets.new(names[:expiry_ets], [:set, :public, :named_table])
    Supervisor.start_link(__MODULE__, [names, module], name: names[:sup_name])
  end

  def init([names, module]) do
    [ worker(Mem.Proxy, [names]),
      worker(Mem.Cleaner, [names, module]),
      supervisor(Mem.Worker.Supervisor, [names]),
    ] |> supervise(strategy: :one_for_all)
  end
end
