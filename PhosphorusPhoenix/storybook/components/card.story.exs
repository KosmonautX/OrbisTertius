defmodule Storybook.Components.Card do
  use PhxLiveStorybook.Story, :component

  def function, do: &PhosWeb.CoreComponents.card/1

  def default_body do
    [
      """
      <div>
        Body
      </div>
      """
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          title: "Some card title"
        },
        slots: default_body()
      },
      %Variation{
        id: :with_actions,
        attributes: %{
          title: "Some title"
        },
        slots: List.flatten(default_body(), [
          """
          <:actions>
            <button class="bg-blue-400 text-white rounded px-4 py-2">Save</button>
          </:actions>
          """
        ])
      }
    ]
  end
end
