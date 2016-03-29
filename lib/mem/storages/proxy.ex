defmodule Mem.Storages.Proxy do

  defmacro __using__(opts) do
    name = opts |> Keyword.fetch!(:name)

    quote do
      @storage __MODULE__
      @process Mem.Utils.process_name(:proxy, unquote(name))

      def create do
        :ets.new(@storage, [:set, :public, :named_table, :compressed, read_concurrency: true])
      end

      def set(hash, pid) do
        :ets.insert(@storage, {hash, pid})
        :ok
      end

      def take_worker(hash) do
        ( with [{_, pid}] when is_pid(pid) <- :ets.lookup(@storage, hash),
               true                        <- Process.alive?(pid),
          do: {:take, pid}
        ) |> case do
          {:take, pid} -> pid
          _            -> nil
        end
      end

    end
  end

end
