defmodule Phos.Orbject.Structure do

  use Ecto.Schema
  import Ecto.Changeset

  alias Phos.Orbject

  @primary_key{:id, :binary_id, autogenerate: false}
  embedded_schema do
    field(:archetype, :string)
    embeds_many :media, Media do
      field(:access, :string)
      field(:essence, :string)
      field(:resolution, :string)
      field(:height, :integer)
      field(:width, :integer)
      field(:count, :integer)
      field(:ext, :string)
      field(:path, :string)
    end
  end

  def apply_user_changeset(attrs) do
    apply_action(
      %Orbject.Structure{}
      |> cast(attrs, [:archetype, :id])
      |> cast_embed(:media, with: &Orbject.Structure.user_media_changeset/2), :user_media)
  end

  def apply_orb_changeset(attrs) do
    apply_action(
      %Orbject.Structure{}
      |> cast(attrs, [:archetype, :id])
      |> cast_embed(:media, with: &Orbject.Structure.orb_media_changeset/2), :user_media)
  end


  def user_media_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:access, :essence, :resolution, :height, :width, :ext])
    |> validate_inclusion(:access, ["protected", "public"])
    |> validate_inclusion(:essence, ["banner", "profile"])
    |> validate_inclusion(:resolution, ["lossy", "lossless"])
    |> validate_required([:access, :essence])
  end

  def orb_media_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:access, :essence, :count, :resolution, :height, :width, :ext])
    |> validate_inclusion(:access, ["public"])
    |> validate_inclusion(:essence, ["banner"])
    |> validate_number(:count, less_than: 6)
    |> validate_inclusion(:resolution, ["lossy", "lossless"])
    |> validate_required([:access, :essence])
  end

end
