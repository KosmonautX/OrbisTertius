defmodule Storybook.Components.Modal do
  use PhxLiveStorybook.Story, :component

  alias PhosWeb.CoreComponents

  def function, do: &CoreComponents.modal/1
  def description, do: "Modal example in story book"

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          id: "some_id",
          show: false,
          inner_block: [],
          on_cancel: {:eval, ~s|JS.push("close")|},
          on_confirm: {:eval, ~s|JS.push("open")|}
        }
      },
    ]
  end
end
