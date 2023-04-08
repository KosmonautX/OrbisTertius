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
          on_cancel: {:eval, ~s|JS.push("close")|},
          on_confirm: {:eval, ~s|JS.push("close")|}
        },
        slots: [
          "Are you sure?",
          ~s|<:confirm>OK</:confirm>|,
          ~s|<:cancel>Cancel</:cancel>|
        ]
      },
      %Variation{
        id: :with_title,
        attributes: %{
          id: "some_id",
          show: false,
          on_cancel: {:eval, ~s|JS.push("close")|},
          on_confirm: {:eval, ~s|JS.push("close")|}
        },
        slots: [
          ~s|<:title>Sample title</:title>|,
          "Are you sure?",
          ~s|<:confirm>OK</:confirm>|,
          ~s|<:cancel>Cancel</:cancel>|
        ]
      },
      %Variation{
        id: :with_subtitle,
        attributes: %{
          id: "some_id",
          show: false,
          on_cancel: {:eval, ~s|JS.push("close")|},
          on_confirm: {:eval, ~s|JS.push("close")|}
        },
        slots: [
          ~s|<:title>Sample title</:title>|,
          ~s|<:subtitle>Sample subtitle</:subtitle>|,
          "Are you sure?",
          ~s|<:confirm>OK</:confirm>|,
          ~s|<:cancel>Cancel</:cancel>|
        ]
      },
    ]
  end
end
