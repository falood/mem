defmodule Mem.Cleaners.LRU do

  defmacro __using__(_) do
    quote do

      def callback(cmd, key, _)
      when cmd in [:set, :expire] do
        do_update(key, Mem.Utils.now)
      end

      def callback(cmd, key)
      when cmd in [:get, :ttl, :update] do
        do_update(key, Mem.Utils.now)
      end

      def callback(:del, key) do
        do_delete(key)
      end

      def callback(_, _) do
      end

    end
  end

end
