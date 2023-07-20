defmodule Phos.TeleBot.CreateOrbFSM do
  defstruct [:telegram_id, :state, path: "orb/create", data: %{orb: %Phos.Action.Orb{title: "", media: false, payload: %{inner_title: ""}, central_geohash: ""},
    media: %Phos.Orbject.Structure{archetype: "ORB"}, location_type: ""},
    metadata: %{}]
  alias Phos.TeleBot.{StateManager, CreateOrb}
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
    print_description_text(struct)
    {:ok, %{struct | state: "description"}}
  end

  def before_transition(struct, "location", "description"), do: print_description_text(struct)
  def before_transition(%{data: %{orb: %{payload: %{inner_title: inner_title}}}} = struct, "description", "location"), do: print_location_text(struct)
  # def before_transition(struct, "location", "current_location"), do: print_currentlocation_text(struct)
  # def before_transition(struct, "current_location", "media"), do: print_media_text(struct)
  def before_transition(struct, "media", "location"), do: print_location_text(struct)
  def before_transition(%{data: %{location_type: type, orb: %{central_geohash: geohash}}} = struct, "location", "media"), do: print_media_text(struct)
  def before_transition(struct, "preview", "media"), do: print_media_text(struct)
  def before_transition(%{data: %{location_type: type, orb: %{central_geohash: geohash, payload: %{inner_title: inner_title}}}} = struct, _initial_state, "preview"), do: print_preview_text(struct)

  defp print_description_text(struct) do
    ExGram.send_message(struct.telegram_id, Template.orb_creation_description_builder(%{}),
      parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard())
    {:ok, struct}
  end

  defp print_location_text(struct) do
    {:ok, user} = BotCore.get_user_by_telegram(struct.telegram_id)
    ExGram.send_message(struct.telegram_id, "Great! Where should we post to?", parse_mode: "HTML",
      reply_markup: Button.build_createorb_location_inlinekeyboard(user))
    {:ok, struct}
  end

  defp print_currentlocation_text(struct) do
    ExGram.send_message(struct.telegram_id, "Send your location with the 📎 button below.", parse_mode: "HTML", reply_markup: Button.build_current_location_button())
    {:ok, struct}
  end

  defp print_media_text(struct) do
    ExGram.send_message(struct.telegram_id, "Almost there! Add an image to make things interesting?\n<i>(Use the 📎 button to attach image)</i>",
      parse_mode: "HTML", reply_markup: Button.build_createorb_media_inlinekeyboard())
    {:ok, struct}
  end

  defp print_preview_text(struct) do
    {:ok, user} = BotCore.get_user_by_telegram(struct.telegram_id)
    {:ok, %{branch: %{data: %{media: %{media: media}} = data} = branch}} = StateManager.get_state(struct.telegram_id)

    if Enum.empty?(media) do
      ExGram.send_message(struct.telegram_id, Template.orb_creation_preview_builder(data),
        parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
    else
      ExGram.send_photo(struct.telegram_id, "https://media.cnn.com/api/v1/images/stellar/prod/191212182124-04-singapore-buildings.jpg?q=w_2994,h_1996,x_3,y_0,c_crop", caption: Template.orb_creation_preview_builder(data),
        parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
    end
    {:ok, struct}
  end
end
