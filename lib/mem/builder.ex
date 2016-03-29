defmodule Mem.Builder do

  def create_data_storage_module(persistence, module, env) do
    "Elixir." <> name = module |> to_string
    storage           = persistence && Mem.Storages.Mnesia.Data || Mem.Storages.ETS.Data
    module_name       = Mem.Utils.storage_name(:data, name)
    quote do
      defmodule unquote(module_name) do
        use unquote(storage)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

  def create_ttl_storage_module(persistence, module, env) do
    "Elixir." <> name = module |> to_string
    storage           = persistence && Mem.Storages.Mnesia.TTL || Mem.Storages.ETS.TTL
    module_name       = Mem.Utils.storage_name(:ttl, name)
    quote do
      defmodule unquote(module_name) do
        use unquote(storage)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

  def create_lru_storage_module(persistence, module, env) do
    "Elixir." <> name = module |> to_string
    storage           = persistence && Mem.Storages.Mnesia.LRU || Mem.Storages.ETS.LRU
    module_name       = Mem.Utils.storage_name(:lru, name)
    quote do
      defmodule unquote(module_name) do
        use unquote(storage), name: unquote(name)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

  def create_proxy_storage_module(module, env) do
    "Elixir." <> name = module |> to_string
    storage           = Mem.Storages.Proxy
    module_name       = Mem.Utils.storage_name(:proxy, name)
    quote do
      defmodule unquote(module_name) do
        use unquote(storage), name: unquote(name)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

  def create_proxy_process_module(module, env) do
    "Elixir." <> name = module |> to_string
    storage           = Mem.Processes.Proxy
    module_name       = Mem.Utils.process_name(:proxy, name)
    quote do
      defmodule unquote(module_name) do
        use unquote(storage), name: unquote(name)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

  def create_worker_process_module(storages, module, env) do
    "Elixir." <> name = module |> to_string
    process           = Mem.Process.Worker
    module_name       = Mem.Utils.process_name(:worker, name)
    quote do
      defmodule unquote(module_name) do
        use unquote(process), storages: unquote(storages)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

  def create_ttl_process_module(storages, module, env) do
    "Elixir." <> name = module |> to_string
    process           = Mem.Process.TTLCleaner
    module_name       = Mem.Utils.process_name(:ttl, name)
    quote do
      defmodule unquote(module_name) do
        use unquote(process), storages: unquote(storages)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

  def create_lru_process_module(storages, mem_size, mem_strategy, module, env) do
    "Elixir." <> name = module |> to_string
    process           = Mem.Process.LRUCleaner
    module_name       = Mem.Utils.process_name(:lru, name)
    quote do
      defmodule unquote(module_name) do
        use unquote(process),
          storages: unquote(storages),
          mem_size: unquote(mem_size),
          mem_strategy: unquote(mem_strategy)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

  def create_proxy_module(storages, processes, worker_number, module, env) do
    "Elixir." <> name = module |> to_string
    module_name       = Mem.Utils.proxy_name(name)
    quote do
      defmodule unquote(module_name) do
        use Mem.Proxy,
          storages: unquote(storages),
          processes: unquote(processes),
          worker_number: unquote(worker_number)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

  def create_supervisor_module(storages, processes, module, env) do
    "Elixir." <> name = module |> to_string
    module_name       = Mem.Utils.supervisor_name(name)
    quote do
      defmodule unquote(module_name) do
        use Mem.Supervisor,
          storages: unquote(storages),
          processes: unquote(processes)
      end
    end |> Code.eval_quoted([], env)
    module_name
  end

end
