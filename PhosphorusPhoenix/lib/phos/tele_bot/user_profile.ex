defmodule Phos.TeleBot.Core.UserProfile do
  alias Phos.TeleBot.{Config, StateManager, CreateOrb, ProfileFSM}
  alias Phos.TeleBot.Core, as: BotCore
  alias Phos.TeleBot.StateManager
  alias Phos.TeleBot.Components.{Template, Button}
  alias Phos.Users
  alias Phos.Users.User

  def edit_name_prompt(telegram_id, message_id) do
    {:ok, user_state} = StateManager.new_state(telegram_id)
    user_state
    |> Map.put(:branch, %ProfileFSM{telegram_id: telegram_id, state: "name",
      metadata: %{message_id: message_id}})
    |> StateManager.update_state(telegram_id)

    ExGram.edit_message_text("What shall we call you?", chat_id: telegram_id, message_id: message_id |> String.to_integer(),
      parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end

  def edit_bio_prompt(telegram_id, message_id) do
    {:ok, user_state} = StateManager.new_state(telegram_id)
    user_state
    |> Map.put(:branch, %ProfileFSM{telegram_id: telegram_id, state: "bio",
      metadata: %{message_id: message_id}})
    |> StateManager.update_state(telegram_id)
    ExGram.edit_message_text("Let's setup your bio. Share your hobbies or skills",
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end

  def edit_location_prompt(telegram_id, message_id) do
    {:ok, user} = BotCore.get_user_by_telegram(telegram_id)
    ExGram.edit_message_text("<b>You can set up your home, work and live location</b>\n\n<u>Click on the button to set your location.</u>",
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_location_button(user, message_id))
  end

  # ExGram.send_message(telegram_id, text, reply_markup: Button.build_current_location_button())

  def edit_locationtype_prompt(telegram_id, "live") do
    ExGram.send_message(telegram_id, "You must share your current/live location to update your location.\n\n<i>(Use the 📎 button to send location)</i>", parse_mode: "HTML")
    {:ok, user_state} = StateManager.new_state(telegram_id)
    user_state
    |> Map.put(:branch, %ProfileFSM{telegram_id: telegram_id, state: "livelocation",
      data: %{location_type: "live"}})
    |> StateManager.update_state(telegram_id)
  end
  def edit_locationtype_prompt(telegram_id, location_type) do
    ExGram.send_message(telegram_id, "Please type your postal code or send your location for #{location_type} location.\n\n<i>(Use the 📎 button to send location)</i>", parse_mode: "HTML")
    {:ok, user_state} = StateManager.new_state(telegram_id)
    user_state
    |> Map.put(:branch, %ProfileFSM{telegram_id: telegram_id, state: "location",
      data: %{location_type: location_type}})
    |> StateManager.update_state(telegram_id)
  end

  def edit_picture_prompt(telegram_id, message_id) do
    {:ok, user_state} = StateManager.new_state(telegram_id)
    user_state
    |> Map.put(:branch, %ProfileFSM{telegram_id: telegram_id, state: "picture",
      metadata: %{message_id: message_id}})
    |> StateManager.update_state(telegram_id)
    ExGram.edit_message_text("<b>Send a picture</b>\n\nSpice up your profile with a profile picture!\n\n<i>(Use the 📎 button to attach image)</i>",
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end

  def set_picture(%{integrations: %{telegram_chat_id: telegram_id}} = user, payload) do
    media = [%{
      access: "public",
      essence: "profile",
      resolution: "lossy"
    }]
    with {:ok, media} <- Phos.Orbject.Structure.apply_media_changeset(%{id: user.id, archetype: "USR", media: media}),
     {:ok, %User{} = user} <- Users.update_user(user, %{media: true}) do
      resolution = %{"150x150" => "lossy", "1920x1080" => "lossless"}
      for res <- ["150x150", "1920x1080"] do
        {:ok, dest} = Phos.Orbject.S3.put("USR", user.id, "public/profile/#{resolution[res]}")
        [hd | tail] = payload |> get_in(["photo"]) |> Enum.reverse()
        {:ok, %{file_path: path}} = ExGram.get_file(hd |> get_in(["file_id"]))
        {:ok, %HTTPoison.Response{body: image} = response} = HTTPoison.get("https://api.telegram.org/file/bot#{Config.get(:bot_token)}/#{path}")
        path = "/tmp/" <> (:crypto.strong_rand_bytes(30) |> Base.url_encode64()) <> ".png"
        File.write!(path , image)
        HTTPoison.put(dest, {:file, path})
        File.rm(path)
      end

      {:ok, %{branch: branch } = user_state} = StateManager.get_state(telegram_id)
      ExGram.send_message(telegram_id, "Your profile picture has been updated!")
      StateManager.delete_state(telegram_id)
      case branch do
        %{data: %{return_to: "post"}} ->
          BotCore.post_orb(telegram_id)
        _ ->
          {:ok, user} = BotCore.get_user_by_telegram(telegram_id)
          open_user_profile(user)
      end

     else
      err ->
        IO.inspect("Something went wrong: set_user_profile_picture #{err}")
    end
  end

  def open_user_profile(user), do: open_user_profile(user, nil)
  def open_user_profile(user, ""), do: open_user_profile(user, nil)
  def open_user_profile(%{integrations: %{telegram_chat_id: telegram_id}} = user, nil) when not is_nil(user) do
    with {:ok, %{message_id: message_id}} <- ExGram.send_message(telegram_id, Template.profile_text_builder(user), parse_mode: "HTML") do
      ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id, reply_markup: Button.build_settings_button(message_id))
    else
      {:error, err} ->
        IO.inspect("Something went wrong: open_user_profile for telegram_id: #{telegram_id}, #{err}")
        BotCore.error_fallback(telegram_id, err)
    end
  end
  def open_user_profile(%{integrations: %{telegram_chat_id: telegram_id}} = user, message_id) when not is_nil(user) do
    ExGram.edit_message_text(Template.profile_text_builder(user), chat_id: telegram_id, message_id: message_id |> String.to_integer(),
      parse_mode: "HTML", reply_markup: Button.build_settings_button(message_id))
  end
  def open_user_profile(_,_), do: {:error, :user_not_found}
end
