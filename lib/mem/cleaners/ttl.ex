defmodule Mem.Cleaners.TTL do

  defmacro __using__(_) do
    quote do

      def callback(cmd, key, ttl) when cmd in [:set, :expire] do
        time =
          if is_nil(ttl) do
            10000000000000000 + Mem.Utils.now
          else
            ttl
          end
        do_update(key, time)
      end

      def callback(:del, key) do
        do_delete(key)
      end

      def callback(_, _) do
      end

    end
  end


end
