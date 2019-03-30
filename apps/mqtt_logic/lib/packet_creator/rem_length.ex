defmodule RemLength do
  use Bitwise

  def encode_rem_len(encoded_bytes, 0) do
    encoded_bytes
  end

  def encode_rem_len(encoded_bytes, len) do
    byte = rem(len, 128)
    len = div(len, 128)

    encoded_bytes =
      case len > 0 do
        true ->
          encoded_bytes ++ [byte ||| 128]

        _ ->
          encoded_bytes ++ [byte]
      end

    encode_rem_len(encoded_bytes, len)
  end

  def decode_rem_length(encoded_bytes) do
    multiplier = 1

    case multiplier < 128 * 128 * 128 do
      true ->
        loop_decode(multiplier, 0, encoded_bytes)

      _ ->
        nil
    end
  end

  def loop_decode(_, value, []) do
    value
  end

  def loop_decode(multiplier, value, [byte | rest_encoded]) do
    value = value + (byte &&& 127) * multiplier
    multiplier = multiplier * 128

    loop_decode(multiplier, value, rest_encoded)
  end
end
