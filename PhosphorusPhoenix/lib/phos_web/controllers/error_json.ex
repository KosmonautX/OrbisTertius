defmodule PhosWeb.ErrorJSON do
  # def render("404.json", _assigns) do
  #   %{errors: %{detail: "Not Found"}}
  # end

  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  def render(template, _assigns) do
    %{errors: %{message: Phoenix.Controller.status_message_from_template(template)}}
  end
end
