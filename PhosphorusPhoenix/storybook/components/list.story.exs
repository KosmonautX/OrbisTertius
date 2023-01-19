defmodule Storybook.Components.List do
  use PhxLiveStorybook.Story, :component

  def function, do: &PhosWeb.CoreComponents.list/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: [
          ~s|<:item title="Title">Some title</:item>|,
          ~s|<:item title="Date"><%= Date.utc_today %></:item>|,
          ~s|<:item title="Description">Some title description</:item>|
        ]
      }
    ]
  end

  def slots do
    [
      %Slot{
        id: :item,
        doc: "Item in list, can be multiple",
        required: true
      }
    ]
  end
end
