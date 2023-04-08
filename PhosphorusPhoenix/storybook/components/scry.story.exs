defmodule Storybook.Components.Scry do
  use PhxLiveStorybook.Story, :component

  def function, do: &PhosWeb.CoreComponents.scry_orb/1

  def variations do
    [
      %Variation{
        id: :with_out_location,
        attributes: %{
          timezone: %{timezone: "UTC", timezone_offset: 0},
          orb: %Phos.Action.Orb{
            initiator: %Phos.Users.User{
              id: "",
              username: "sowmiya",
            },
            payload: %Phos.Action.Orb_Payload{where: "vellore"},
            id: "86073073-2e88-4584-9bbf-ffd14cfbf16f",
            title: "Good Morning",
            inserted_at: ~N[2023-02-22 11:13:15]
          }
        }
      }
    ]
  end
end
