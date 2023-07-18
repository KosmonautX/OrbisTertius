defmodule Phos.TeleBot.ProfileFSM do
  defstruct [:telegram_id, :state, data: %{return_to: ""}, path: "editprofile", metadata: %{message_id: "", last_active: DateTime.utc_now() |> DateTime.to_unix()}]
  alias Phos.TeleBot.Core, as: BotCore
  alias Phos.TeleBot.Components.{Button, Template}

  use Fsmx.Struct, transitions: %{
    "start" => ["onboarding", "name", "bio", "location", "picture"],
    :*  => "start"
  }

  def before_transition(struct, _initial, "name"), do: print_name_text(struct)
  def before_transition(struct, _initial, "bio"), do: print_bio_text(struct)
  def before_transition(struct, _initial, "picture"), do: print_picture_text(struct)
  def before_transition(struct, _initial, "location"), do: {:ok, struct}
  def before_transition(%{data: %{email: email}} = struct, _initial_state, "link_account") do
    {:ok, %{struct | data: %{email: email}}}
  end

  defp print_name_text(%{telegram_id: telegram_id, metadata: %{message_id: message_id}} = struct) do
    ExGram.edit_message_text("What shall we call you?", chat_id: telegram_id, message_id: message_id |> String.to_integer(),
      parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
    {:ok, struct}
  end

  defp print_bio_text(%{telegram_id: telegram_id, metadata: %{message_id: message_id}} = struct) do
    ExGram.edit_message_text("Let's setup your bio. Share your hobbies or skills",
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
    {:ok, struct}
  end

  defp print_picture_text(%{telegram_id: telegram_id, metadata: %{message_id: message_id}} = struct) do
    ExGram.edit_message_text("Spice up your profile with a profile picture! Send a picture.",
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
    {:ok, struct}
  end

  # defp print_location_text(%{telegram_id: telegram_id, metadata: %{message_id: message_id}} = struct) do
  #   with {:ok, user} <- BotCore.get_user_by_telegram(telegram_id) do
  #     ExGram.send_message(telegram_id, "Please type your postal code or send your location for your location",
  #       parse_mode: "HTML", reply_markup: Button.build_location_button(user, message_id))
  #     {:ok, struct}
  #   else
  #     err -> BotCore.error_fallback(telegram_id, err)
  #   end
  # end
end
