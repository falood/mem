defmodule Mem.Storages.Mnesia.LRU do

  defmacro __using__(_) do
    quote do
      @name :"#{__MODULE__}.Mnesia"

      def create do
        :mnesia.create_table(@name, [
          type:        :ordered_set,
          attributes:  [:ttl, :key],
          index:       [:key],
          disc_copies: [node]
        ])
      end

      def update(key, time) do
        ttl = {time, System.unique_integer}
        case :mnesia.dirty_index_read(@name, key, 3) do
          [] -> nil
          [{_, old_ttl, ^key}] ->
            :mnesia.dirty_delete(@name, old_ttl)
        end
        :mnesia.dirty_write(@name, {@name, ttl, key})
        :ok
      end

      def delete(key) do
        case :mnesia.dirty_index_read(@name, key, 3) do
          [] -> nil
          [{_, old_ttl, ^key}] ->
            :mnesia.dirty_delete(@name, old_ttl)
        end
        :ok
      end

      def flush do
        :mnesia.clear_table(@name)
      end

      def drop_first do
        case :mnesia.dirty_first(@name) do
          :"$end_of_table" ->
            nil
          ttl              ->
            [{_, _, key}] = :mnesia.dirty_read(@name, ttl)
            key
        end
      end

    end
  end

end
