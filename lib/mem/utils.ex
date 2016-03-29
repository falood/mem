defmodule Mem.Utils do
  def now do
    {i, j, k} = :erlang.timestamp
    i * 1_000_000_000_000 + j * 1_000_000 + k
  end

  def format_space_size(nil), do: nil
  def format_space_size(x) when is_integer(x), do: x
  def format_space_size(x) when is_binary(x) do
    x |> String.codepoints |> do_format(0)
  end

  defp do_format([], result), do: result
  defp do_format([h | t], result)
  when h in [" ", "B", "b"] do
    do_format(t, result)
  end
  defp do_format([h | t], result)
  when h in ["k", "K"] do
    do_format(t, result * 1024)
  end
  defp do_format([h | t], result)
  when h in ["m", "M"] do
    do_format(t, result * 1024 * 1024)
  end
  defp do_format([h | t], result)
  when h in ["g", "G"] do
    do_format(t, result * 1024 * 1024 * 1024)
  end
  defp do_format([h | t], result)
  when h in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] do
    h = h |> String.to_integer
    do_format(t, result * 10 + h)
  end


  def proxy_name(sub_name) do
    Module.concat([Mem, Instances, sub_name, Proxy])
  end

  def supervisor_name(sub_name) do
    Module.concat([Mem, Instances, sub_name, Supervisor])
  end

  def storage_name(name, sub_name) do
    suffix =
      %{ data:   Data,
         ttl:    TTL,
         lru:    LRU,
         proxy:  Proxy,
      }
    Map.has_key?(suffix, name) || raise "wrong module name"
    Module.concat([Mem, Instances, sub_name, Storage, suffix[name]])
  end

  def process_name(name, sub_name) do
    suffix =
      %{ ttl:    TTL,
         lru:    LRU,
         proxy:  Proxy,
         worker: Worker,
      }
    Map.has_key?(suffix, name) || raise "wrong module name"
    Module.concat([Mem, Instances, sub_name, Process, suffix[name]])
  end

end
