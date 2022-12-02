defmodule PhosWeb.ErrorView do
  def render("404.json", _assigns) do
    %{errors: %{detail: "Internal Server Error 400 json"}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal Server Error 500 json"}}
  end

  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
