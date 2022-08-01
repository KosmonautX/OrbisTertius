defmodule PhosWeb.API.UserProfileView do
  use PhosWeb, :view
  alias PhosWeb.API.UserProfileView

  def render("index.json", %{user_profile: user_profile}) do
    %{data: render_many(user_profile, UserProfileView, "user_profile.json")}
  end

  def render("show.json", %{user_profile: user_profile}) do
    %{data: render_one(user_profile, UserProfileView, "user_profile.json")}
  end

  def render("user_profile.json", %{user_profile: user_profile}) do
    %{
      username: user_profile.username,
      bio: user_profile.public_profile.bio,
      birthday: user_profile.public_profile.birthday,
      occupation: user_profile.public_profile.occupation,
      profile_pic: user_profile.profile_pic,
      honorific: user_profile.public_profile.honorific,
      media: user_profile.media,
      media_asset: (if user_profile.media, do: Phos.Orbject.S3.get!("USR", user_profile.id, "50x50"))
    }
  end
end
