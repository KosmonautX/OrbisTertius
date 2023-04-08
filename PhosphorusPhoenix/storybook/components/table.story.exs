defmodule Storybook.Components.Table do
  use PhxLiveStorybook.Story, :component

  def function, do: &PhosWeb.CoreComponents.table/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          id: "default_table",
          row_click: nil,
          rows: [],
        },
        let: :data,
        slots: [
          """
            <:col :let={data} label="ID"><%= Map.get(data, :id) %></:col>
          """,
          """
            <:col :let={data} label="Title"><%= Map.get(data, :title) %></:col>
          """,
          """
            <:col :let={data} label="Description"><%= Map.get(data, :description) %></:col>
          """,
          """
          <:action>
            <button>Save</button>
          </:action>
          """,
        ]
      }
    ]
  end
end
