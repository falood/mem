defmodule Mem.Processes.Proxy do

  defmacro __using__(opts) do
    name = opts |> Keyword.fetch!(:name)

    quote do
      @storage Mem.Utils.storage_name(:proxy, unquote(name))
      @worker  Mem.Utils.process_name(:worker, unquote(name))

      use GenServer

      def create_worker(hash) do
        GenServer.call(__MODULE__, {:create_worker, hash})
      end

      def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      def init([]) do
        {:ok, []}
      end

      def handle_call({:create_worker, hash}, _from, state) do
        result =
          case @storage.take_worker(hash) do
            nil ->
              pid = create_worker()
              @storage.set(hash, pid)
              pid
            pid -> pid
          end
        {:reply, result, state}
      end


      defp create_worker do
        case @worker.start do
          {:ok, pid} -> pid
          _          -> raise "create worker error"
        end
      end

    end
  end

end
