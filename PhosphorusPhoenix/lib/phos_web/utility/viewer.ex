defmodule PhosWeb.Util.Viewer do

  @moduledoc """

  For our Viewer Helper function that moulds data Models into Views

  """
  # Orb Mapper
  def orb_mapper(orbs) do
    Enum.map(orbs, fn orb ->
      %{
        id: orb.orbs.id,
        title: orb.orbs.title,
        active: orb.orbs.active,
        media: orb.orbs.media,
        extinguish: orb.orbs.extinguish,
        when: orb.orbs.payload.when,
        where: orb.orbs.payload.where,
        info: orb.orbs.payload.info,
        tip: orb.orbs.payload.tip,
        orb_nature: orb.orbs.orb_nature,
        initiator: orb.orbs.initiator,
        traits: orb.orbs.traits
      }
    end)
  end

  # Update Orbs Mapper
  def update_orb_mapper(orb) do
      %{
        "title" => orb["title"],
        "media" => orb["media"],
        "payload" => orb["payload"],
        "traits" => orb["traits"]
      }
  end

  # Index Live Orbs
  def live_orb_mapper(orbs) do
    Enum.filter(orbs, fn orb -> orb.active == true end)
  end
end
