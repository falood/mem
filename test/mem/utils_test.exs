defmodule Mem.UtilsTest do
  use ExUnit.Case
  import Mem.Utils

  test "format_space_size" do
    assert is_nil(format_space_size(nil))
    assert 200 = format_space_size(200)
    assert 3072 = format_space_size("3k")
    assert 12582912 = format_space_size("12m")
    assert 1073741824 = format_space_size("1G")
    assert 104857600 = format_space_size("100 MB")
  end

end
