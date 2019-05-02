defmodule PacketHandler do
  use Bitwise

  def extract_connect_flags(flags_byte, flags_array \\ [], offset \\ 0)

  def extract_connect_flags(_flags_byte, flags_array, 8) do
    flags_array
  end

  def extract_connect_flags(flags_byte, flags_array, offset) do
    IO.inspect(flags_byte)
    extract_connect_flags(flags_byte >>> 1, [flags_byte &&& 1 | flags_array], offset + 1)
  end
end
