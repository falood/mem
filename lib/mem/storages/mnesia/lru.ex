defmodule Mem.Storages.Mnesia.LRU do

  defmacro __using__(_) do
    quote do
      @data  :"#{__MODULE__}.Mnesia.Data"
      @index :"#{__MODULE__}.Mnesia.Index"

      def create do
        :mnesia.create_table(@data,  [type: :set, disc_copies: [node]])
        :mnesia.create_table(@index, [type: :ordered_set, disc_copies: [node]])
      end

      def memory_used do
        :mnesia.table_info(@data, :memory) + :mnesia.table_info(@index, :memory)
      end

      def update(key, time) do
        index_key = {time, System.unique_integer}
        case :mnesia.dirty_read(@data, key) do
          []         -> nil
          [{_, _, idx}] ->
            :mnesia.dirty_delete(@index, idx)
        end
        :mnesia.dirty_write(@data,  {@data, key, index_key})
        :mnesia.dirty_write(@index, {@index, index_key, key})
        :ok
      end

      def delete(key) do
        case :mnesia.dirty_read(@data, key) do
          []         -> nil
          [{_, _, idx}] ->
            :mnesia.dirty_delete(@index, idx)
            :mnesia.dirty_delete(@data, key)
        end
        :ok
      end

      def flush do
        :mnesia.clear_table(@data)
        :mnesia.clear_table(@index)
        :ok
      end

      def drop_first do
        case :mnesia.dirty_first(@index) do
          :"$end_of_table" ->
            nil
          idx ->
            [{_, _, key}] = :mnesia.dirty_read(@index, idx)
            :mnesia.dirty_delete(@index, idx)
            :mnesia.dirty_delete(@data, key)
            key
        end
      end

    end
  end

end
