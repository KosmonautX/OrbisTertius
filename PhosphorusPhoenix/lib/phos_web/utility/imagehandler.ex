defmodule PhosWeb.Util.ImageHandler do

  @moduledoc """
  For all your Image Handling Needs
  """

  def resize_file(path, dimension, ext) do
    dim = String.split(dimension, "x")
    |> Enum.map(fn d -> String.to_integer(d) end)
    resize_file(path, List.first(dim), List.last(dim), ext)
  end

  def resize_file(path, width, height, ext) do
    :wx.new()
    save_path = Path.basename(path) <> "#{height}x#{width}"<> ext
    file = path |> String.to_charlist()
    |> :wxImage.new()
    width_a = :wxImage.getWidth(file)
    height_a = :wxImage.getHeight(file)
    width_r = width_a / width
    height_r =  height_a / height
    white = [r: 255 , g: 255 , b: 255]
    cond do
      height_r < 1 && width_r < 1 ->
        file
      |> :wxImage.resize({width, height}, {round((width-width_a)/2), round((height-height_a)/2)}, white)
      |> :wxImage.saveFile(save_path)

      height > 1 || width > 1 ->
        scaling_r= 1 /max(height_r,width_r)
        position = {round((width - (scaling_r * width_a))/2), round((height - (scaling_r * height_a))/2)}
        file
        |> :wxImage.scale(round(width_a* scaling_r), round(height_a* scaling_r), [quality: 1])
        |> :wxImage.resize({width, height}, position , white)
        |> :wxImage.saveFile(save_path)

      height == 1 && width == 1 ->
        :wxImage.saveFile(file, save_path)
    end
    :wx.destroy()

    save_path
    end

end
