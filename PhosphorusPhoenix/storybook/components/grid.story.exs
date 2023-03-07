defmodule Storybook.Components.Gird do
  use PhxLiveStorybook.Story, :component

  def function, do: &PhosWeb.CoreComponents.admin_grid/1

  def variations do
    [
      %Variation{
        id: :Admin,
        attributes: %{
          user: %{id: "", username: "sowmi", public_profile: %{public_name: "Sowmiya Thangadurai", birthday: "10/10/2001", traits: ["dog"]}},
        },
      }
    ]
  end
end
