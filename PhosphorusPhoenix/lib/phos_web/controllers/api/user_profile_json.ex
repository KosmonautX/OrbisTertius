defmodule PhosWeb.API.UserProfileJSON do
  alias PhosWeb.Util.Viewer

  def index(%{user_profile: profile}), do: %{data: Enum.map(profile, &user_profile_json/1)}
  def show(%{user_profile: profile, media: media}) when not is_nil(media) do
    %{
      data: user_profile_json(profile),
      media_herald: Phos.Orbject.S3.put_all!(media),
    }
  end
  def show(%{user_profile: profile}), do: %{ data: user_profile_json(profile)}
  def show(%{integration: integration}), do: %{ data: user_integration_json(integration)}

  defp user_profile_json(profile), do: Viewer.user_mapper(profile)
  defp user_integration_json(profile), do: Viewer.user_integration_mapper(profile)
end
