defmodule PhosWeb.API.UserProfileView do
  use PhosWeb, :view
  alias PhosWeb.API.UserProfileView
  alias Phos.Orbject.S3

  def render("index.json", %{user_profile: user}) do
    %{data: render_many(user, UserProfileView, "user.json")}
  end


  def render("show.json", %{user_profile: user, media: media}) do
    %{data: render_one(user, UserProfileView, "user.json"),
      media: (unless is_nil(media),
       do: Phos.Orbject.S3.put_all!(media))
    }
  end


  def render("show.json", %{user_profile: user}) do
    %{data: render_one(user, UserProfileView, "user.json"),
      media: (if user.media,
       do: Phos.Orbject.S3.get_all!("USR", user.id))
    }
  end


  def render("user.json", %{user_profile: user}) do
    %{
      id: user.id,
      username: user.username,
      fyr_id: user.fyr_id,
      email: user.email,
      profile_pic: user.profile_pic,
      profile: PhosWeb.Util.Viewer.user_profile_mapper(user),
    }

  end
end
