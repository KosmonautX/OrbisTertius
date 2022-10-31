defmodule PhosWeb.API.UserProfileView do
  use PhosWeb, :view
  alias PhosWeb.API.UserProfileView
  alias Phos.Orbject.S3

  def render("index.json", %{user_profile: user}) do
    %{data: render_many(user, UserProfileView, "user.json")}
  end


  def render("show.json", %{user_profile: user, media: media}) do
    %{data: render_one(user, UserProfileView, "user.json"),
      media_herald: (unless is_nil(media),
       do: S3.put_all!(media))
    }
  end


  def render("show.json", %{user_profile: user}) do
    %{data: render_one(user, UserProfileView, "user.json")}
  end

  def render("show.json", %{integration: user}) do
    %{data: render_one(user, UserProfileView, "integration.json")}
  end

  def render("integration.json", %{integration: user}) do
    PhosWeb.Util.Viewer.user_integration_mapper(user)
  end


  def render("user.json", %{user_profile: user}) do
    PhosWeb.Util.Viewer.user_mapper(user)
  end
end
