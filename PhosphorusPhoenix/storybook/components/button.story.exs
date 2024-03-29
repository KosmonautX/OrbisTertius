defmodule Storybook.Components.Button do
  use PhxLiveStorybook.Story, :component

  def function, do: &PhosWeb.CoreComponents.button/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          tone: :primary,
        },
        slots: ["Primary"]
      },
      %Variation{
        id: :success,
        attributes: %{
          tone: :success,
        },
        slots: ["Success"]
      },
      %Variation{
        id: :warning,
        attributes: %{
          tone: :warning,
        },
        slots: ["Warning"]
      },
      %Variation{
        id: :danger,
        attributes: %{
          tone: :danger,
        },
        slots: ["Danger"]
      },
      %Variation{
        id: :icons,
        attributes: %{
          tone: :icons,
        },
        slots: ["Icons"]
      }
    ]
  end
end
