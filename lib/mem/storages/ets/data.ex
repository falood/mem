defmodule Mem.Storages.ETS.Data do
  @moduledoc """
  Original Data Storage

  Backend:     ETS
  Table Type:  set
  Data Format: {key, value}
  Index:       key
  """

  defmacro __using__(_) do
    quote do
      @name :"#{__MODULE__}.ETS"

      def create do
        :ets.new(@name, [:set, :public, :named_table, :compressed, write_concurrency: true])
      end

      def memory_used do
        :ets.info(@name, :memory)
      end

      def get(key) do
        case :ets.lookup(@name, key) do
          [{^key, value}] -> {:ok, value}
          []              -> {:err, nil}
        end
      end

      def set(key, value) do
        :ets.insert(@name, {key, value})
      end

      def del(key) do
        :ets.delete(@name, key)
      end

      def flush do
        :ets.delete_all_objects(@name)
      end

    end
  end

end
