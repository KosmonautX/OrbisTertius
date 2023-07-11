defmodule Phos.TeleBot.CreateOrbFSM do
  defstruct [:telegram_id, :state, :data]
  alias Phos.TeleBot.CreateOrbPath
  alias Phos.TeleBot.Components.Template

  use Fsmx.Struct, transitions: %{
    "home" => "createorb_description",
    "createorb_description" => ["createorb_location"],
    "createorb_location" => ["createorb_description", "createorb_media"],
    "createorb_media" => ["createorb_location", "createorb_preview"],
    "createorb_preview" => "createorb_media",
    "*" => ["home"]
  }

  def before_transition(struct, "home", "createorb_description") do
    CreateOrbPath.createorb_print_description_text(struct.telegram_id)
    {:ok, %{struct | state: "createorb_description", data: %{inner_title: "", media: %{}, mediacount: 1,
    location_type: "", geolocation: %{central_geohash: ""}} }}
  end

  # createorb_description -> createorb_location
  def before_transition(struct, "createorb_location", "createorb_description") do
    CreateOrbPath.createorb_print_description_text(struct.telegram_id)
    {:ok, struct}
  end
  def before_transition(%{data: %{inner_title: inner_title}} = struct, "createorb_description", "createorb_location") do
    CreateOrbPath.createorb_print_location_text(struct.telegram_id)
    {:ok, struct}
  end

  def before_transition(struct, "createorb_media", "createorb_location") do
    CreateOrbPath.createorb_print_location_text(struct.telegram_id)
    {:ok, struct}
  end
  # createorb_location -> createorb_media
  def before_transition(%{data: %{location_type: type, geolocation: %{central_geohash: geohash}}} = struct, "createorb_location", "createorb_media") do
    CreateOrbPath.createorb_print_media_text(struct.telegram_id)
    {:ok, struct}
  end

  # def before_transition(struct, "createorb_media", "createorb_preview") do
  #   CreateOrbPath.createorb_print_media_text(struct.telegram_id)
  #   {:ok, struct}
  # end

  def before_transition(struct, "createorb_preview", "createorb_media") do
    CreateOrbPath.createorb_print_media_text(struct.telegram_id)
    {:ok, struct}
  end

  # user has to input his inner_title, info, location to reach the "preview" state
  def before_transition(%{data: %{inner_title: inner_title, location_type: type, geolocation: %{central_geohash: geohash}}} = struct, _initial_state, "createorb_preview") do
    CreateOrbPath.createorb_print_preview_text(struct.telegram_id)
    {:ok, struct}
  end
end
