defmodule Phos.TeleBot.CreateOrbFSM do
  defstruct [:telegram_id, :state, :data]
  alias Phos.TeleBot.{StateManager, CreateOrbPath}
  alias Phos.TeleBot.Components.{Template, Button}

  use Fsmx.Struct, transitions: %{
    "home" => "createorb_description",
    "createorb_description" => ["createorb_location"],
    "createorb_location" => ["createorb_description", "createorb_current_location", "createorb_media"],
    "createorb_current_location" => "createorb_media",
    "createorb_media" => ["createorb_location", "createorb_preview"],
    "createorb_preview" => "createorb_media"
  }

  # /post -> createorb_description <-> createorb_location <-> createorb_media <-> createorb_preview
  #                   |                         |                 ^
  #                   v                         v                 |
  #               main_menu                  createorb_current_location

  def before_transition(struct, "home", "createorb_description") do
    createorb_print_description_text(struct)
    {:ok, %{struct | state: "createorb_description", data: %{inner_title: "", media: %{},
    location_type: "", geolocation: %{central_geohash: ""}} }}
  end

  def before_transition(struct, "createorb_location", "createorb_description"), do: createorb_print_description_text(struct)
  def before_transition(%{data: %{inner_title: inner_title}} = struct, "createorb_description", "createorb_location"), do: createorb_print_location_text(struct)
  def before_transition(struct, "createorb_location", "createorb_current_location"), do: createorb_print_currentlocation_text(struct)
  def before_transition(struct, "createorb_current_location", "createorb_media"), do: createorb_print_media_text(struct)
  def before_transition(struct, "createorb_media", "createorb_location"), do: createorb_print_location_text(struct)
  def before_transition(%{data: %{location_type: type, geolocation: %{central_geohash: geohash}}} = struct, "createorb_location", "createorb_media"), do: createorb_print_media_text(struct)
  def before_transition(struct, "createorb_preview", "createorb_media"), do: createorb_print_media_text(struct)
  def before_transition(%{data: %{inner_title: inner_title, location_type: type, geolocation: %{central_geohash: geohash}}} = struct, _initial_state, "createorb_preview"), do: createorb_print_preview_text(struct)

  defp createorb_print_description_text(struct) do
    ExGram.send_message(struct.telegram_id, Template.orb_creation_description_builder(%{}),
      parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard())
    {:ok, struct}
  end

  defp createorb_print_location_text(struct) do
    {:ok, user} = Phos.TeleBot.get_user_by_telegram(struct.telegram_id)
    ExGram.send_message(struct.telegram_id, "Great! Where should we post to?", parse_mode: "HTML",
      reply_markup: Button.build_createorb_location_inlinekeyboard(user))
    {:ok, struct}
  end

  defp createorb_print_currentlocation_text(struct) do
    ExGram.send_message(struct.telegram_id, "Send your location with the 📎 button below.", parse_mode: "HTML", reply_markup: Button.build_current_location_button())
    {:ok, struct}
  end

  defp createorb_print_media_text(struct) do
    ExGram.send_message(struct.telegram_id, "Almost there! Add an image to make things interesting?\n<i>(Use the 📎 button to attach image)</i>",
      parse_mode: "HTML", reply_markup: Button.build_createorb_media_inlinekeyboard())
    {:ok, struct}
  end

  defp createorb_print_preview_text(struct) do
    {:ok, user} = Phos.TeleBot.get_user_by_telegram(struct.telegram_id)
    user_state = StateManager.get_state(struct.telegram_id)

    if Enum.empty?(user_state.data.media) do
      ExGram.send_message(struct.telegram_id, Template.orb_creation_preview_builder(user_state.data),
        parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
    else
      ExGram.send_photo(struct.telegram_id, "https://media.cnn.com/api/v1/images/stellar/prod/191212182124-04-singapore-buildings.jpg?q=w_2994,h_1996,x_3,y_0,c_crop", caption: Template.orb_creation_preview_builder(user_state.data),
        parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
    end
    {:ok, struct}
  end
end
