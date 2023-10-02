defmodule Phos.Action.Blorb do
  use Ecto.Schema
  use Fsmx.Struct, transitions: %{
    "txt" => "*",
    "img" => "*",
    "vid" => "*",
    "*" => ["txt"]
  }

  import Ecto.Changeset, warn: false

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "blorbs" do
    field :type, Ecto.Enum, values: [:txt, :img, :vid]
    field :active, :boolean, default: true
    embeds_one :character, Characteristics do
      field(:content, :string)
      field(:align, :string, default: "justify")
      # media
      field(:count, :integer, virtual: true)
      field(:ext, :string)
      field(:url, :string, virtual: true)
      field(:mimetype, :string, virtual: true)
    end

    belongs_to :orb, Phos.Action.Orb, references: :id, type: Ecto.UUID
    belongs_to :initiator, Phos.Users.User, references: :id, type: Ecto.UUID

    timestamps()
  end

  def changeset(%Phos.Action.Blorb{} = blorb, attrs) do
      blorb
      |> cast(attrs, [:type, :active, :initiator_id])
      |> typed_character_switch()
      |> validate_required([:type, :character])
  end

  def typed_character_switch(%{changes: %{type: type}} = changeset) do
    character_changeset = case type do
                           :txt ->
                             &txt_changeset(&1, &2)
                           :img ->
                             &img_changeset(&1, &2)

                           :vid ->
                             &vid_changeset(&1, &2)
                         end

    cast_embed(changeset, :character, with: character_changeset)
  end

  def typed_character_switch(changeset), do: validate_required(changeset, [:type])

  def txt_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:content, :align])
    |> validate_inclusion(:align, ["left", "right", "center", "justify"])
    |> validate_required([:content])
  end

  def img_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:ext, :count])
    |> validate_inclusion(:ext, ["jpeg", "jpg", "png", "gif"])
    |> validate_required([:count])
  end

  def vid_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:ext, :count])
    |> validate_inclusion(:ext, ["mp4", "mov"])
    |> validate_required([:count])
  end
 end
