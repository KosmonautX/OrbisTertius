defmodule Phos.Users.Integrations do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:fcm_token, :string)
    embeds_one :beacon, Beacon, on_replace: :update, primary_key: false do
      embeds_one :location, Location, on_replace: :update, primary_key: false do
        field :scope, :boolean
        field :unsubscribe, Phos.Ecto.Mapset, of: :integer # {:array, :integer}
        field :subscribe, Phos.Ecto.Mapset, of: :integer
 # {:array, :integer}
      end
    end
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:fcm_token])
    |> cast_embed(:beacon, with: &beacon_changeset/2)
  end

  def beacon_changeset(beacon, attrs) do
    beacon
    |> cast(attrs, [])
    |> cast_embed(:location, with: &location_beacon_changeset/2)
  end

  def location_beacon_changeset(beacon, attrs) do
    beacon
    |> cast(attrs, [:scope, :subscribe, :unsubscribe])
  end

end
