defmodule Phos.TeleBot.Core.UserProfile do
  alias Phos.TeleBot.{Config, StateManager, CreateOrbPath, ProfileFSM}
  alias Phos.TeleBot.Core, as: BotCore
  alias Phos.TeleBot.StateManager
  alias Phos.TeleBot.Components.{Template, Button}
  alias Phos.Users
  alias Phos.Users.User

  def edit_user_profile_name(telegram_id, message_id) do
    with {:ok, user_state} <- StateManager.get_state(telegram_id) do
      user_state = struct(ProfileFSM, Map.from_struct(%ProfileFSM{telegram_id: telegram_id, state: user_state.state, path: "editprofile",
        metadata: %{message_id: message_id, last_active: DateTime.utc_now() |> DateTime.to_unix()}}))
      case Fsmx.transition(user_state, "name") do
        {:ok, user_state} ->
          StateManager.set_state(telegram_id, user_state)
        {:error, err} ->
          BotCore.error_fallback(telegram_id, err)
        end
    else
      err -> BotCore.error_fallback(telegram_id, err)
    end
  end

  def edit_user_profile_bio(telegram_id, message_id) do
    with {:ok, user_state} <- StateManager.get_state(telegram_id) do
      user_state = struct(ProfileFSM, Map.from_struct(%ProfileFSM{telegram_id: telegram_id, state: user_state.state, path: "editprofile",
        metadata: %{message_id: message_id, last_active: DateTime.utc_now() |> DateTime.to_unix()}}))
      case Fsmx.transition(user_state, "bio") do
        {:ok, user_state} ->
          StateManager.set_state(telegram_id, user_state)
        {:error, err} ->
          BotCore.error_fallback(telegram_id, err)
        end
    else
      err -> BotCore.error_fallback(telegram_id, err)
    end
  end

  def edit_user_profile_location(telegram_id, message_id) do
    with {:ok, user} <- BotCore.get_user_by_telegram(telegram_id) do
      ExGram.edit_message_text("You can set up your home, work and live location\n\nJust send your pinned location or live location after hitting the button",
        chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_location_button(user, message_id))
    else
      err -> BotCore.error_fallback(telegram_id, err)
    end
  end

  # ExGram.send_message(telegram_id, text, reply_markup: Button.build_current_location_button())

  def edit_user_profile_locationtype(telegram_id, location_type) do
    ExGram.send_message(telegram_id, "Please type your postal code or send your location for #{location_type} location.")
    with {:ok, user_state} <- StateManager.get_state(telegram_id) do
      user_state = struct(ProfileFSM, Map.from_struct(%ProfileFSM{telegram_id: telegram_id, state: user_state.state, path: "editprofile",
        data: %{location_type: location_type}, metadata: %{last_active: DateTime.utc_now() |> DateTime.to_unix()}}))
      case Fsmx.transition(user_state, "location") do
        {:ok, user_state} ->
          StateManager.set_state(telegram_id, user_state)
        {:error, err} ->
          BotCore.error_fallback(telegram_id, err)
      end
    else
      err -> BotCore.error_fallback(telegram_id, err)
    end
  end

  def edit_user_profile_picture(telegram_id, message_id) do
    with {:ok, user_state} <- StateManager.get_state(telegram_id) do
      user_state = struct(ProfileFSM, Map.from_struct(%ProfileFSM{telegram_id: telegram_id, state: user_state.state, path: "editprofile",
        data: %{}, metadata: %{message_id: message_id, last_active: DateTime.utc_now() |> DateTime.to_unix()}}))
      case Fsmx.transition(user_state, "picture") do
        {:ok, user_state} ->
          ExGram.edit_message_text("Spice up your profile with a profile picture! Send a picture.",
            chat_id: telegram_id, message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
          StateManager.set_state(telegram_id, user_state)
        {:error, err} ->
          BotCore.error_fallback(telegram_id, err)
      end
    else
      err -> BotCore.error_fallback(telegram_id, err)
    end
  end

  def set_user_profile_picture(user, payload) do
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
        {:ok, %HTTPoison.Response{body: image}} = HTTPoison.get("https://api.telegram.org/file/bot#{Config.get(:bot_token)}/#{path}")
        path = "/tmp/" <> (:crypto.strong_rand_bytes(30) |> Base.url_encode64()) <> ".png"
        File.write!(path , image)
        HTTPoison.put(dest, {:file, path})
        File.rm(path)
      end

      {:ok, user_state} = StateManager.get_state(user.integrations.telegram_chat_id)
      case user_state do
        %{data: %{return_to: "post"}} ->
          BotCore.post_orb(user.integrations.telegram_chat_id)
        _ ->
          ExGram.send_message(user.integrations.telegram_chat_id, "Your profile picture has been updated", reply_markup: Button.build_menu_inlinekeyboard())
      end

     else
      err ->
        IO.inspect("Something went wrong: set_user_profile_picture #{err}")
    end
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
