defmodule Phos.TeleBot.CreateOrbFSM do
  defstruct [:telegram_id, :state, path: "orb/create", data: %{orb: %Phos.Action.Orb{title: "", media: false, payload: %{inner_title: ""}, central_geohash: ""},
    media: %Phos.Orbject.Structure{archetype: "ORB"}, location_type: ""},
    metadata: %{}]
  alias Phos.TeleBot.{StateManager}
  alias Phos.TeleBot.Components.{Template, Button}
  alias Phos.TeleBot.Core, as: BotCore

  use Fsmx.Struct, transitions: %{
    "description" => ["location"],
    "location" => ["description", "media"],
    "media" => ["location", "preview"],
    "preview" => "media"
  }

  # /post -> description <-> location <-> media <-> preview
  #                |                |             ^
  #                v                |             |
  #            main_menu            \____________/

  def before_transition(struct, "start", "description") do
    print_description_prompt(struct)
    {:ok, %{struct | state: "description"}}
  end

  def before_transition(struct, "location", "description"), do: print_description_prompt(struct)
  def before_transition(%{data: %{orb: %{payload: %{inner_title: _inner_title}}}} = struct, "description", "location"), do: print_location_prompt(struct)
  def before_transition(struct, "media", "location"), do: print_location_prompt(struct)
  def before_transition(%{data: %{location_type: _type, orb: %{central_geohash: _geohash}}} = struct, "location", "media"), do: print_media_prompt(struct)
  def before_transition(struct, "preview", "media"), do: print_media_prompt(struct)
  def before_transition(%{data: %{location_type: _type, orb: %{central_geohash: _geohash, payload: %{inner_title: _inner_title}}}} = struct, _initial_state, "preview"), do: print_preview_prompt(struct)

  defp print_description_prompt(%{telegram_id: telegram_id} = struct) do
    ExGram.send_message(telegram_id, Template.orb_creation_description_builder(%{}),
      parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard())
    {:ok, struct}
  end

  defp print_location_prompt(%{telegram_id: telegram_id} = struct) do
    {:ok, user} = BotCore.get_user_by_telegram(struct.telegram_id)
    ExGram.send_message(telegram_id, "Great! Where should we post to?", parse_mode: "HTML",
      reply_markup: Button.build_createorb_location_inlinekeyboard(user))
    {:ok, struct}
  end

  # defp print_currentlocation_prompt(%{telegram_id: telegram_id} = struct) do
  #   ExGram.send_message(telegram_id, "Send your location with the 📎 button below.", parse_mode: "HTML", reply_markup: Button.build_current_location_button())
  #   {:ok, struct}
  # end

  defp print_media_prompt(%{telegram_id: telegram_id} = struct) do
    ExGram.send_message(telegram_id, "Almost there! Add an image to make things interesting?\n<i>(Use the 📎 button to attach image)</i>",
      parse_mode: "HTML", reply_markup: Button.build_createorb_media_inlinekeyboard())
    {:ok, struct}
  end

  defp print_preview_prompt(%{telegram_id: telegram_id} = struct) do
    {:ok, %{branch: %{data: %{orb: orb, media: %{media: media}} = data}}} = StateManager.get_state(struct.telegram_id)
    if Enum.empty?(media) do
      ExGram.send_message(telegram_id, Template.orb_creation_preview_builder(data),
        parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
    else
      if String.contains?(PhosWeb.Endpoint.url, "localhost") do
        # For development
        ExGram.send_photo(telegram_id, "https://d1e00ek4ebabms.cloudfront.net/production/f046ab80-21a7-40e8-b56e-6e8076d47a82.jpg", caption: Template.orb_creation_preview_builder(data),
          parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
      else
        # For production
        ExGram.send_photo(telegram_id, Phos.Orbject.S3.get!("ORB", orb.id, "public/banner/lossless"), caption: Template.orb_creation_preview_builder(data),
          parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
      end
    end
    {:ok, struct}
  end
end
