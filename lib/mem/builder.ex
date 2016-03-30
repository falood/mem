defmodule Mem.Builder do

  def create_proxy(opts) do
    module_name = Mem.Utils.proxy_name(opts[:name])
    env = %{opts[:env] | file: to_string(module_name)}
    quote do
      defmodule unquote(module_name) do
        use Mem.Proxy, unquote(opts)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end


  def create_supervisor(opts) do
    module_name = Mem.Utils.supervisor_name(opts[:name])
    env = %{opts[:env] | file: to_string(module_name)}
    quote do
      defmodule unquote(module_name) do
        use Mem.Supervisor, unquote(opts)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end


  def create_storages(opts) do
    [ :proxy, :data, :ttl |
      (is_nil(opts[:mem_size]) && [] || [:lru])
    ] |> Enum.map(fn name ->
      base = do_base(name, opts)
      {name, do_create_storages(name, base, opts)}
    end)
  end

  defp do_base(:data, opts) do
    opts[:persistence] && Mem.Storages.Mnesia.Data || Mem.Storages.ETS.Data
  end

  defp do_base(:ttl, opts) do
    opts[:persistence] && Mem.Storages.Mnesia.TTL || Mem.Storages.ETS.TTL
  end

  defp do_base(:lru, opts) do
    opts[:persistence] && Mem.Storages.Mnesia.LRU || Mem.Storages.ETS.LRU
  end

  defp do_base(:proxy, _) do
    Mem.Storages.Proxy
  end

  defp do_create_storages(name, base, opts) do
    module_name = Mem.Utils.storage_name(name, opts[:name])
    env = %{opts[:env] | file: to_string(module_name)}
    quote do
      defmodule unquote(module_name) do
        use unquote(base), unquote(opts)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end


  def create_processes(opts) do
    do_create_processes(:worker, opts)
    [ :proxy, :ttl |
      (is_nil(opts[:mem_size]) && [] || [:lru])
    ] |> Enum.map(fn name ->
      {name, do_create_processes(name, opts)}
    end)
  end

  defp do_create_processes(name, opts) do
    base =
      %{ proxy:  Mem.Processes.Proxy,
         worker: Mem.Processes.Worker,
         ttl:    Mem.Processes.TTLCleaner,
         lru:    Mem.Processes.LRUCleaner,
       } |> Map.get(name)
    module_name = Mem.Utils.process_name(name, opts[:name])
    env = %{opts[:env] | file: to_string(module_name)}
    quote do
      defmodule unquote(module_name) do
        use unquote(base), unquote(opts)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

end
