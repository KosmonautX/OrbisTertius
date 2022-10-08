defmodule Phos.Orbject.Structure do

  use Ecto.Schema
  import Ecto.Changeset

  alias Phos.Orbject

  embedded_schema do
  field(:archetype, :string)
  field(:entity, :binary_id)
  field(:essence, :string)
  field(:resolution, :string)
  field(:height, :integer)
  field(:width, :integer)
  field(:mimetype, :string)
  field(:path, :string)
  end

  def usermedia_changeset(attrs) do
    %Orbject.Structure{}
    |> cast(attrs, [:archetype, :entity, :essence, :resolution, :height, :width, :mimetype])
    |> validate_inclusion(:archetype, ["USR"])
    |> validate_inclusion(:essence, ["banner", "profile"])
    |> validate_inclusion(:resolution, ["preview", "raw"])
  end

end
