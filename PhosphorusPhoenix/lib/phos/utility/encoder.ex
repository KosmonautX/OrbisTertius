defmodule Phos.Utility.Encoder do
  def encode_lpath(id), do: String.replace(id, "-", "")
  def encode_lpath(id, labels) when is_list(labels) do
    encode_lpath(id, Enum.join(labels, "."))
  end
  def encode_lpath(id, parent_string) do
    case String.contains?(parent_string, "-") do
      true -> encode_lpath(parent_string)
      _ -> parent_string
    end
    |> Kernel.<>(".")
    |> Kernel.<>(encode_lpath(id))
  end

  def decode_lpath(<<time_low::binary-size(8), time_mid::binary-size(4), version::binary-size(4), clock::binary-size(4), rest::binary>>) do
    "#{time_low}-#{time_mid}-#{version}-#{clock}-#{rest}"
  end
end
