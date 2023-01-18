defmodule PhosWeb.Api.DevLandJSON do
  def token(%{token: _token} = data), do: data
end
