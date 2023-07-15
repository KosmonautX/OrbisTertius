defmodule Phos.TeleBot.Core.UserProfile do
  alias Phos.TeleBot.Core, as: BotCore
  alias Phos.TeleBot.StateManager
  alias Phos.TeleBot.Components.{Template, Button}

  def edit_user_profile_name(telegram_id, ""), do: edit_user_profile_name(telegram_id, nil)
  def edit_user_profile_name(telegram_id, nil) do
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "edit_profile_name"}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.send_message(telegram_id, "What shall we call you?", parse_mode: "HTML" , reply_markup: Button.build_main_menu_inlinekeyboard())
  end
  def edit_user_profile_name(telegram_id, message_id) do
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "edit_profile_name#{message_id}"}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.edit_message_text("What shall we call you?", chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end

  def edit_user_profile_bio(telegram_id, ""), do: edit_user_profile_bio(telegram_id, nil)
  def edit_user_profile_bio(telegram_id, nil) do
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "edit_profile_bio"}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.send_message(telegram_id, "Let's setup your bio. Share your hobbies or skills",
      parse_mode: "HTML" , reply_markup: Button.build_main_menu_inlinekeyboard())
  end
  def edit_user_profile_bio(telegram_id, message_id) do
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "edit_profile_bio#{message_id}"}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.edit_message_text("Let's setup your bio. Share your hobbies or skills",
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end

  def edit_user_profile_location(telegram_id, ""), do: edit_user_profile_location(telegram_id, nil)
  def edit_user_profile_location(telegram_id, nil) do
    {:ok, user} = BotCore.get_user_by_telegram(telegram_id)
    ExGram.send_message(telegram_id, "You can set up your home, work and live location\n\nJust send your pinned location or live location after hitting the button",
          parse_mode: "HTML", reply_markup: Button.build_location_button(user))
  end
  def edit_user_profile_location(telegram_id, message_id) do
    {:ok, user} = BotCore.get_user_by_telegram(telegram_id)
    ExGram.edit_message_text("You can set up your home, work and live location\n\nJust send your pinned location or live location after hitting the button",
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_location_button(user, message_id))
  end

  def edit_user_profile_picture(telegram_id, ""), do: edit_user_profile_picture(telegram_id, nil)
  def edit_user_profile_picture(telegram_id, nil) do
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "set_profile_picture"}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.send_message(telegram_id, "Spice up your profile with a profile picture! Send a picture.",
      parse_mode: "HTML")
  end
  def edit_user_profile_picture(telegram_id, message_id) do
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "set_profile_picture"}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.edit_message_text("Spice up your profile with a profile picture! Send a picture.",
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end

  def open_user_profile(user), do: open_user_profile(user, nil)
  def open_user_profile(user, ""), do: open_user_profile(user, nil)
  def open_user_profile(%{integrations: %{telegram_chat_id: telegram_id}} = user, nil) do
    {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id, Template.profile_text_builder(user),
      parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id, reply_markup: Button.build_settings_button(message_id))
  end
  def open_user_profile(%{integrations: %{telegram_chat_id: telegram_id}} = user, message_id) do
    ExGram.edit_message_text(Template.profile_text_builder(user), chat_id: telegram_id, message_id: message_id |> String.to_integer(),
      parse_mode: "HTML", reply_markup: Button.build_settings_button(message_id))
  end
end
