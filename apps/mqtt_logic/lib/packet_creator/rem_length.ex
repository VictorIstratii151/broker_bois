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

  def decode_rem_length(encoded_bytes, value \\ 0, multiplier \\ 1)

  def decode_rem_length([], value, _) do
    value
  end

  def decode_rem_length([byte | rest_encoded], value, multiplier) do
    case multiplier <= 128 * 128 * 128 do
      true ->
        value = value + (byte &&& 127) * multiplier

        case byte &&& 128 do
          0 ->
            value

          _ ->
            multiplier = multiplier * 128
            decode_rem_length(rest_encoded, value, multiplier)
        end

      _ ->
        nil
    end
  end
end
