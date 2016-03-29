defmodule Mem.Storages.Mnesia.TTL do

  defmacro __using__(_) do
    quote do
      @name :"#{__MODULE__}.Mnesia"

      def create do
        # Application.load :mnesia
        # Application.put_env :mnesia, :dir, '/tmp/mn'
        # :mnesia.start
        # :mnesia.change_table_copy_type(:schema, node, :disc_copies)
        :mnesia.create_table(@name, [type: :set, disc_copies: [node]])
      end

      def memory_used do
        :mnesia.table_info(@name, :memory)
      end

      def get(key) do
        case :mnesia.dirty_read(@name, key) do
          [{_, ^key, value}] -> {:ok, value}
          []                 -> {:err, nil}
        end
      end

      def set(key, value) do
        :mnesia.dirty_write(@name, {@name, key, value})
      end

      def del(key) do
        :mnesia.dirty_delete(@name, key)
      end

      def flush do
        :mnesia.clear_table(@name)
      end


      def first do
        :mnesia.dirty_first(@name)
      end

      def next(key) do
        :mnesia.dirty_next(@name, key) |> IO.inspect
      end


    end
  end

end
