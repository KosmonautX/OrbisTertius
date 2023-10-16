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
    field :pop, :boolean, default: false, virtual: true
    embeds_one :character, Characteristics, on_replace: :delete do
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
    |> cast(attrs, [:type, :active, :orb_id, :initiator_id])
    |> typed_character_switch(attrs)
    |> validate_required([:type, :character])
  end

  def mutate_changeset(%Phos.Action.Blorb{} = blorb, attrs) do
    blorb
    |> cast(attrs, [:id, :type, :active, :orb_id])
    |> typed_character_switch(attrs)
    |> validate_required([:type, :character])
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  #when type changes
  def typed_character_switch(changeset, %{type: type}), do: typed_character_switch(changeset, %{"type" => type})
  def typed_character_switch(changeset, %{"type" => type}) do
    character_changeset = case type do
                            "txt" ->
                              &txt_changeset(&1, &2)
                            "img" ->
                              &img_changeset(&1, &2)
                            "vid" ->
                              &vid_changeset(&1, &2)
                          end

    cast_embed(changeset, :character, with: character_changeset)
  end

  def typed_character_switch(changeset, _attrs), do: validate_required(changeset, [:type])

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
    |> validate_required([:ext])
  end

  def vid_changeset(structure, attrs) do
    structure
    |> cast(attrs, [:ext, :count])
    |> validate_inclusion(:ext, ["mp4", "mov"])
    |> validate_required([:ext])
  end
end
