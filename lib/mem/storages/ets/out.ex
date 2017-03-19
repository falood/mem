defmodule Mem.Storages.ETS.Out do
  @moduledoc """
  Replacement Storage

  Two addition ets tables used to storage replacement information:

  Backend:     ETS
  Table Type:  set
  Data Format: {key, {out_timestamp, unique_integer}}
  Index:       key

  Backend:     ETS
  Table Type:  ordered_set
  Data Format: {{out_timestamp, unique_integer}, key}
  Index:       {out_timestamp, unique_integer}

  * out_timestamp decided by maxmemory strategy, `:fifo` `:lru` or `ttl`
  """

  defmacro __using__(_) do
    quote do
      @data  :"#{__MODULE__}.ETS.Data"
      @index :"#{__MODULE__}.ETS.Index"

      def create do
        :ets.new(@data,  [:set,         :public, :named_table, :compressed])
        :ets.new(@index, [:ordered_set, :public, :named_table, :compressed])
      end

      def memory_used do
        :ets.info(@data, :memory) + :ets.info(@index, :memory)
      end

      def update(key, time) do
        index_key = {time, System.unique_integer}
        case :ets.lookup(@data, key) do
          []         -> nil
          [{_, idx}] ->
            :ets.delete(@index, idx)
        end
        :ets.insert(@data,  {key, index_key})
        :ets.insert(@index, {index_key, key})
        :ok
      end

      def delete(key) do
        case :ets.lookup(@data, key) do
          []         -> nil
          [{_, idx}] ->
            :ets.delete(@index, idx)
            :ets.delete(@data, key)
        end
        :ok
      end

      def flush do
        :ets.delete_all_objects(@data)
        :ets.delete_all_objects(@index)
        :ok
      end

      def drop_first do
        case :ets.first(@index) do
          :"$end_of_table" ->
            nil
          idx ->
            [{_, key}] = :ets.lookup(@index, idx)
            :ets.delete(@index, idx)
            :ets.delete(@data, key)
            key
        end
      end

    end
  end

end
