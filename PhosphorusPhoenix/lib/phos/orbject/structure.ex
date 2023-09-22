defmodule Phos.Orbject.Structure do

  use Ecto.Schema
  import Ecto.Changeset

  alias Phos.Orbject

  @primary_key{:id, :binary_id, autogenerate: false}
  embedded_schema do
    field(:archetype, :string)
    field(:wildcard, :boolean)
    embeds_many :media, Media do
      field(:access, :string)
      field(:essence, :string)
      field(:essence_id, :binary_id)
      field(:resolution, :string)
      field(:height, :integer)
      field(:width, :integer)
      field(:count, :integer)
      field(:ext, :string)
      field(:path, :string)
      field(:url, :string)
      field(:mimetype, :string)
    end
  end

  def apply_media_changeset(attrs) do
      %Orbject.Structure{}
      |> cast(attrs, [:archetype, :id, :wildcard])
      |> media_embed_switch()
  end

  def media_embed_switch(changeset) do
    changeset.changes.archetype
    |> case do
         "USR" ->
           apply_user_changeset(changeset)
         "ORB" ->
           apply_orb_changeset(changeset)
         "MEM" ->
           apply_memory_changeset(changeset)
       end
  end

  def apply_orb_changeset(changeset) do
    changeset
    |> cast_embed(:media, with: &Orbject.Structure.orb_media_changeset/2)
    |> apply_action(:orb_media)
  end

  def apply_user_changeset(changeset) do
    changeset
    |> cast_embed(:media, with: &Orbject.Structure.user_media_changeset/2)
    |> apply_action(:user_media)
  end

  def apply_memory_changeset(changeset) do
    changeset
    |> cast_embed(:media, with: &Orbject.Structure.memory_media_changeset/2)
    |> apply_action(:memory_media)
  end


  def user_media_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:access, :essence, :resolution, :ext])
    |> validate_inclusion(:access, ["protected", "public"])
    |> validate_inclusion(:essence, ["banner", "profile"])
    |> validate_inclusion(:resolution, ["lossy", "lossless"])
    |> validate_inclusion(:ext, ["jpeg", "jpg", "png", "gif"])
    |> validate_required([:access, :essence])
  end

  def orb_media_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:access, :essence, :count, :resolution, :ext, :essence_id])
    |> validate_inclusion(:access, ["public"])
    |> validate_inclusion(:essence, ["banner", "profile", "blorb"])
    |> validate_number(:count, greater_than: -1, less_than: 6)
    |> validate_inclusion(:resolution, ["lossy", "lossless"])
    |> validate_inclusion(:ext, ["jpeg", "jpg", "png", "gif", "mp4", "mov", "mp3"])
    |> validate_required([:access, :essence])
  end

  def memory_media_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:access, :essence, :count, :resolution, :ext])
    |> validate_inclusion(:access, ["public"])
    |> validate_inclusion(:essence, ["profile"])
    |> validate_number(:count, greater_than: -1, less_than: 6)
    |> validate_inclusion(:resolution, ["lossy", "lossless"])
    |> validate_inclusion(:ext, ["jpeg", "jpg", "png", "gif", "mp4", "mov", "mp3"])
    |> validate_required([:access, :essence])
  end
 end
