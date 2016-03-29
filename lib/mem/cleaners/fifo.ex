defmodule Mem.Cleaners.FIFO do

  defmacro __using__(_) do
    quote do

      def callback(:set, key, _) do
        GenServer.cast(__MODULE__, {:update, key, Mem.Utils.now})
      end

      def callback(_, _, _) do
      end

      def callback(:del, key) do
        GenServer.cast(__MODULE__, {:delete, key})
      end

      def callback(_, _) do
      end

    end
  end

end
