defmodule PhosWeb.Utility.Encoder do

  def encode_lpath(id, parent_path) do
    parent_path <> "." <> hd(String.split(id, "-"))
  end

  def encode_lpath(id) do
    hd(String.split(id, "-"))
  end
end
