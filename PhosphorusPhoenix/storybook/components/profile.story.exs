defmodule Storybook.Components.Profile do
  use PhxLiveStorybook.Story, :component
  def function, do: &PhosWeb.CoreComponents.user_profile_banner/1

  def default_body do
    [
      """
      <div>
      <Heroicons.camera class="bottom-4 -ml-4 lg:w-11 lg:h-11 h-10 w-10 fill-white" />
      </div>
      """
    ]
  end

  def variations do
    [
      %Variation{
        id: :with_out_location,
        attributes: %{
          user: %Phos.Users.User{id: "", username: "sowmiya"}
        },
        slots: default_body()
      },
      %Variation{
        id: :with_location,
        attributes: %{
          show_location: true,
          user: %Phos.Users.User{
            id: "",
            username: "sowmiya",
            public_profile: %{territories: [614268617229336575, 614268613720801279]}
          }
        },
        slots: default_body()
      }
    ]
  end
end
