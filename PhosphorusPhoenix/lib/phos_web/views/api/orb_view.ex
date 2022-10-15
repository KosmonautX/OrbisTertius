defmodule PhosWeb.API.OrbView do
  use PhosWeb, :view
  alias PhosWeb.API.OrbView

  def render("index.json", %{orbs: orbs}) do
    %{data: render_many(orbs, OrbView, "orb.json")}
  end

  def render("paginated.json", %{orbs: orbs}) do
    %{data: render_many(orbs.data, OrbView, "orb.json"), meta: orbs.meta}
  end

  def render("paginated.json", %{locations: loc_orbs}) do
    data = loc_orbs.data |> Enum.map(fn loc -> loc.orbs end)
    %{data: render_many(data, OrbView, "orb.json"), meta: loc_orbs.meta}
  end

  def render("show.json", %{orb: orb, media: media}) do
    %{data: render_one(orb, OrbView, "orb.json"),
      media_herald: (unless is_nil(media),
       do: Phos.Orbject.S3.put_all!(media))
    }
  end

  def render("show.json", %{orb: orb}) do
    %{data: render_one(orb, OrbView, "orb.json")}
  end

  def render("orb.json", %{orb: orb}) do
    PhosWeb.Util.Viewer.orb_mapper(orb)
  end
end
