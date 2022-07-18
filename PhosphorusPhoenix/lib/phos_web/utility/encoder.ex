defmodule PhosWeb.Utility.Encoder do


  #   @doc """
  #   Encodes lpath with comment id and parent_path (in string).

  #   ## Examples

  #       iex> encode_lpath("789", "123.456")
  #       123.456.789

  #   """
  #
  def encode_lpath(id, parent_path_string) do
    parent_path_string <> "." <> hd(String.split(id, "-"))
  end

  #   @doc """
  #   Encodes lpath with comment id.

  #   ## Examples

  #       iex> encode_lpath("123")
  #       123

  #   """
  #
  def encode_lpath(id) do
    hd(String.split(id, "-"))
  end
end
