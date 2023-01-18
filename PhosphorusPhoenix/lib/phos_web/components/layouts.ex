defmodule PhosWeb.Layouts do
  use PhosWeb, :html

  embed_templates "layouts/*"

  
  def user_menu(assigns)
end
