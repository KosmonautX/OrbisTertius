defmodule Phos.TeleBot do
  use Phoenix.Component
  import PhosWeb.Endpoint, only: [url: 0]
  use PhosWeb, :html

  require Logger
  @bot :phos_telebot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  alias File.Stat
  alias Mix.State
  alias Phos.{Users, Orbject, Action}
  alias Phos.Users.User
  alias __MODULE__.{Config, StateManager}
  alias Phos.TelegramNotification, as: TN

  @keyboard_button_messages ["❌ Cancel", "🔭 Latest Posts", "👤 Profile", "❓ Help", "📎 Media", "📍 Location", "🏡 Home", "🏢 Work", "✈️ Post"]

  # command("debug", description: "DEBUG MENU")
  command("start", description: "Start the interactive bot")
  command("help", description: "Print the bot's help")
  command("post", description: "Post something")
  command("register", description: "Register an account")
  command("profile", description: "View your profile")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  # ====================
  # GENERIC MESSAGES
  # ====================

  def handle({:message, com, %{"chat" => chat} = payload}) when com in [:start] do
    telegram_id = payload |> get_in(["from", "id"])
    # pattern match confirmed_at is not nil
    with {:user_exist, true} <- {:user_exist, Users.telegram_user_exists?(telegram_id)},
         {:user, {:ok, %User{confirmed_at: date}}} when not is_nil(date) <- {:user, Users.get_user_by_telegram(telegram_id |> to_string())} do
          main_menu(payload)
          StateManager.delete_state(telegram_id)
        else
          {:user_exist, false} ->
            create_user(%{"id" => telegram_id})
            ExGram.send_photo(telegram_id, "https://static.wixstatic.com/media/551811_369c449f9d374cddba16aa58ce2e6702~mv2.jpg/v1/fill/w_1920,h_788,al_c,q_85,usm_0.66_1.00_0.01,enc_auto/551811_369c449f9d374cddba16aa58ce2e6702~mv2.jpg", caption: onboarding_text_builder(%{}), reply_markup: build_location_button())
          {:user, _} ->
            ExGram.send_photo(telegram_id, "https://static.wixstatic.com/media/551811_369c449f9d374cddba16aa58ce2e6702~mv2.jpg/v1/fill/w_1920,h_788,al_c,q_85,usm_0.66_1.00_0.01,enc_auto/551811_369c449f9d374cddba16aa58ce2e6702~mv2.jpg", caption: onboarding_text_builder(%{}), reply_markup: build_location_button())
        end

    # get_in(chat, ["id"])
    # |> Users.telegram_user_exists?()
    # |> case do
    #   false ->
    #     create_user(%{"id" => get_in(chat, ["id"])})
    #     ExGram.send_photo(get_in(chat, ["id"]), "https://static.wixstatic.com/media/551811_369c449f9d374cddba16aa58ce2e6702~mv2.jpg/v1/fill/w_1920,h_788,al_c,q_85,usm_0.66_1.00_0.01,enc_auto/551811_369c449f9d374cddba16aa58ce2e6702~mv2.jpg", caption: onboarding_text_builder(%{}), reply_markup: build_location_button())
    #   _ ->
    #     main_menu(payload)
    #     StateManager.delete_state(payload |> get_in(["chat", "id"]))
    # end
  end

  def handle({:message, :help, payload}) do
    ExGram.send_message(payload |> get_in(["chat", "id"]), help_text_builder(%{}))
  end

  @doc """
  Handle the keyboard button messages
  """
  def handle({:message, :text, %{"text" => text} = payload}) when text in @keyboard_button_messages do
    telegram_id = payload |> get_in(["chat", "id"])
    {:ok, user} = Users.get_user_by_telegram(telegram_id |> to_string())
    user_state = StateManager.get_state(telegram_id)

    if is_nil(user.confirmed_at) do
      onboarding_text(payload)
    else
      case text do
        "❌ Cancel" ->
          StateManager.delete_state(telegram_id)
          main_menu(payload)
        "🔭 Latest Posts" ->
          ExGram.send_message(telegram_id, latest_posts_text_builder(user), parse_mode: "HTML", reply_markup: build_latest_posts_inline_button())
        "👤 Profile" ->
          # profilefsm = %Phos.TeleBot.ProfileFSM{state: "profile"}
          # StateManager.set_state(telegram_id, profilefsm)
          ExGram.send_message(telegram_id, profile_text_builder(user), parse_mode: "HTML", reply_markup: build_settings_button())
        "❓ Help" ->
          ExGram.send_message(telegram_id, "Choose section below:", parse_mode: "HTML", reply_markup: build_help_button())
        "📎 Media" ->
          ExGram.send_message(telegram_id, orb_creation_media_builder(%{}), parse_mode: "HTML")
        "📍 Location" ->
          ExGram.send_message(telegram_id, orb_creation_location_builder(user), parse_mode: "HTML", reply_markup: build_createorb_location_button())
        "🏡 Home" ->
          if is_nil(user.private_profile) do
            ExGram.send_message(telegram_id, update_location_text_builder(%{location_type: "home"}), parse_mode: "HTML", reply_markup: build_location_specific_button("Home"))
          else
            geohash =
              case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == "home" end) do
                nil -> nil
                %{geohash: geohash} -> geohash
              end
            if is_nil(geohash) do
              ExGram.send_message(telegram_id, update_location_text_builder(%{location_type: "home"}), parse_mode: "HTML", reply_markup: build_location_specific_button("Home"))
            else
              {_prev, user_state} = get_and_update_in(user_state.data.geolocation.central_geohash, &{&1, geohash})
              {_prev, user_state} = get_and_update_in(user_state.data.location_type, &{&1, :home} )
              StateManager.set_state(telegram_id, user_state)
              ExGram.send_message(telegram_id, orb_creation_preview_builder(user_state.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
            end
          end

        "🏢 Work" ->
          if is_nil(user.private_profile) do
            ExGram.send_message(telegram_id, update_location_text_builder(%{location_type: "work"}), parse_mode: "HTML", reply_markup: build_location_specific_button("Work"))
          else
            geohash =
              case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == "work" end) do
                nil -> nil
                %{geohash: geohash} -> geohash
              end
            if is_nil(geohash) do
              ExGram.send_message(telegram_id, update_location_text_builder(%{location_type: "work"}), parse_mode: "HTML", reply_markup: build_location_specific_button("Work"))
            else
              {_prev, user_state} = get_and_update_in(user_state.data.geolocation.central_geohash, &{&1, geohash})
              {_prev, user_state} = get_and_update_in(user_state.data.location_type, &{&1, :work} )
              StateManager.set_state(telegram_id, user_state)
              ExGram.send_message(telegram_id, orb_creation_preview_builder(user_state.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
            end
          end

        "✈️ Post" when user_state.state in ["create_orb"] ->
          user_state = StateManager.get_state(telegram_id)
          params = %{
            "id" => Ecto.UUID.generate(),
            "expires_in" => "10000",
            "title" => "deprecated",
            "media" => user_state.data.media,
            "inner_title" => user_state.data.inner_title,
            "info" => user_state.data.inner_title,
            "active" => "true",
            "source" => "tele",
            "geolocation" => %{"central_geohash" => user_state.data.geolocation.central_geohash}
          }

          with {:ok, attrs} <- PhosWeb.API.OrbController.orb_constructor(user, params),
              {:ok, media} <- Phos.Orbject.Structure.apply_media_changeset(%{id: attrs["id"], archetype: "ORB", media: user_state.data.media}),
              {:ok, %Phos.Action.Orb{} = orb} <- Phos.Action.create_orb(%{attrs | "media" => true}) do
                  TN.Collector.add(orb)
                  ExGram.send_message(telegram_id, "Orb created successfully!", reply_markup: remove_keyboard())
                  StateManager.delete_state(telegram_id)
              else
                err ->
                  IO.inspect(user_state.data.media)
                  IO.inspect(err)
                  ExGram.send_message(telegram_id, "Please ensure you have filled in all the required fields.")
                  ExGram.send_message(telegram_id, orb_creation_preview_builder(user_state.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
          end
        _ -> nil
      end
    end
  end

  @doc """
  Handle messages as requested by menus (Postal codes, email addresses, createorb inner_title etc.)
  """
  def handle({:message, :text, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    {:ok, user} = Users.get_user_by_telegram(telegram_id |> to_string())

    case StateManager.get_state(telegram_id) do
      %{state: "set_location"} ->
        text = payload |> get_in(["text"])
        # validate text is 5-6 digits
        case get_location_from_postal_json(text) do
          nil ->
            ExGram.send_message(telegram_id, "Invalid postal code. Please try again.")
          _ ->
            %{"address" => address, "lat" => lat, "lon" => lon} = get_location_from_postal_json(text)
            update_user_location(telegram_id, {String.to_float(lat), String.to_float(lon)}, address)
            StateManager.delete_state(telegram_id)
        end

      %{state: "finish_profile_to_post"} ->
        text = payload |> get_in(["text"])
        # validate text is a valid public name
        if text not in @keyboard_button_messages do
          profilefsm = StateManager.get_state(telegram_id)
          case Users.update_pub_user(user, %{"username" => text}) do
            {:ok, _} ->
              # set username from data.profile_fields_checklist
              {_prev, profilefsm} = get_and_update_in(profilefsm.data.profile_fields_checklist, &{&1, true})
              case Fsmx.transition(profilefsm, "set_profile_picture") do
                {:ok, _} ->
                  # {_prev, profilefsm} = get_and_update_in(profilefsm.state, &{&1, "set_profile_picture"})
                  # StateManager.set_state(telegram_id, profilefsm)
                  ExGram.send_message(telegram_id, "Great #{text}! Now let's set your profile picture! \n\nSend a photo.")
                {:error, err} ->
                  ExGram.send_message(telegram_id, "Error transitioning to profile pic.")
              end
            {:error, changeset} ->
              ExGram.send_message(telegram_id, "Username taken. Please choose another username.")
          end
        end

      %{state: "edit_profile_" <> type} ->
        text = payload |> get_in(["text"])
        case type do
          "name" ->
            {:ok, user} = Users.update_user(user, %{public_profile: %{public_name: text}})
            ExGram.send_message(telegram_id, "People will now see you as #{text} from now!" <> profile_text_builder(user), parse_mode: "HTML", reply_markup: build_settings_button())
          "bio" ->
            {:ok, user} = Users.update_user(user, %{public_profile: %{bio: text}})
            ExGram.send_message(telegram_id, "Nice! Your bio has been updated" <> profile_text_builder(user), parse_mode: "HTML", reply_markup: build_settings_button())
        end

      %{state: "onboarding"} = user_state ->
        text = payload |> get_in(["text"])
        is_valid_email = not is_nil(Regex.run(~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i, text))
        user_by_email = Users.get_user_by_email(text)
        case {is_valid_email, user_by_email} do
          {true, nil} ->
            {:ok, user} = User.email_changeset(user, %{email: text}) |> Phos.Repo.update()
            Users.deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
            ExGram.send_message(telegram_id, "An email has been sent to #{text} if it exists. Please check your inbox and follow the instructions to link your account.")
          {true, user} ->
            ExGram.send_message(telegram_id, "You already have an account with us. Would you like to link your telegram to your Scratchbac account?", reply_markup: build_link_account_button())
          {false, _} ->
            ExGram.send_message(telegram_id, "This is not a valid email, please try again or return to /start to cancel")
        end

      %{state: "link_account"} ->
        text = payload |> get_in(["text"])
        # validate email
        case Regex.run(~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i, text) do
          [email, _domain] ->
            case Users.get_user_by_email(email) do
              nil ->
                ExGram.send_message(telegram_id, "No account found with that email. Please try again or return to /start")
              %{integration: %{telegram_chat_id: _}} ->
                ExGram.send_message(telegram_id, "Your account is already linked to a telegram account. Unlink your account at web.scratchbac.com before linking to another telegram account.")
              user ->
                  Users.deliver_telegram_bind_confirmation_instructions(user, telegram_id, &url(~p"/users/bind/telegram/#{&1}"))
                  ExGram.send_message(telegram_id, "An email has been sent to #{email} if it exists. Please check your inbox and follow the instructions to link your account.")
                  StateManager.delete_state(telegram_id)
            end
          nil ->
            ExGram.send_message(telegram_id, "Your email is invalid, please try again or return to /start")
        end

      %{state: "create_orb"} ->
        text = payload |> get_in(["text"])
        # get orb inner_title
        if text not in @keyboard_button_messages do
          user_state = StateManager.get_state(telegram_id)
          # update inner_title in the createorbfsm data if it exists
          {_prev, user_state} = get_and_update_in(user_state.data.inner_title, &{&1, text})
          StateManager.set_state(telegram_id, user_state)
          ExGram.send_message(telegram_id, orb_creation_preview_builder(user_state.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
        end
      _ ->
        nil
    end
  end

  # @doc """
  # Check if meets all necessary profile fields to post or user has a post ongoing, prompt to continue editing or reset
  # """
  def handle({:message, :post, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    user_state = StateManager.get_state(telegram_id)
    {:ok, user} = Users.get_user_by_telegram(telegram_id |> to_string())

    if is_nil(user.confirmed_at) do
      onboarding_text(payload)
    else
      profile_fields_checklist = %{
        username: not is_nil(user.username),
        profile_picture: user.media,
      }
      has_completed_profile_to_post = Enum.all?(profile_fields_checklist, fn {_, v} -> v end)

      case user_state do
        _ when has_completed_profile_to_post ->
          create_fresh_orb_form(telegram_id)
        _ when not has_completed_profile_to_post ->
          ExGram.send_message(telegram_id, incomplete_profile_text_builder(profile_fields_checklist), reply_markup: complete_profile_for_post_button())
        %{state: "create_orb"} ->
          ExGram.send_message(telegram_id, "You have a post creation ongoing, do you wish to continue or restart?", reply_markup: build_existing_post_creation_inline_button())
        _ ->
          nil
      end
    end
  end

  def handle({:message, :register, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    ExGram.send_message(telegram_id, onboarding_text_builder(%{}), reply_markup: build_onboarding_button())
  end

  def handle({:message, :profile, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    {:ok, user} = Users.get_user_by_telegram(telegram_id |> to_string())
    ExGram.send_message(telegram_id, profile_text_builder(user), reply_markup: build_settings_button())
  end

  # def handle({:message, :debug, payload}) do
  #   telegram_id = payload |> get_in(["chat", "id"])

  #   user_state = StateManager.get_state(telegram_id)

  #   if not is_nil(user_state) do
  #     debugmsg = "
  #     payload: #{inspect(payload)}

  #     Current State: #{inspect(user_state.state)}
  #     Current Data: #{inspect(user_state.data)}
  #   "

  #   ExGram.send_message(payload |> get_in(["chat", "id"]), debugmsg)
  #   end
  # end

  # TODO: To confirm whether this works
  def handle({:photo, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    {:ok, user} = Users.get_user_by_telegram(telegram_id |> to_string())
    case StateManager.get_state(telegram_id) do
      %{state: "finish_profile_to_post"} ->
        media = %{
          access: "public",
          essence: "profile",
          resolution: "lossy"
        }
        with {:ok, media} <- Orbject.Structure.apply_media_changeset(%{id: user.id, archetype: "USR", media: media}),
         {:ok, %User{} = user} <- Users.update_user(user, %{media: true}) do
          IO.inspect(media)
          ExGram.send_message(telegram_id, "Profile picture updated!\nYou may now start posting with /post", parse_mode: "HTML")
          StateManager.delete_state(telegram_id)
         else
          _ ->
            IO.inspect("Something went wrong setting picture")
        end
      %{state: "set_profile_picture"} ->
        media = [%{
          access: "public",
          essence: "profile",
          resolution: "lossy"
        }]

        with {:ok, media} <- Orbject.Structure.apply_media_changeset(%{id: user.id, archetype: "USR", media: media}),
         {:ok, %User{} = user} <- Users.update_user(user, %{media: true}) do
          # IO.inspect(media)
          # resolution = %{"150x150" => "lossy", "1920x1080" => "lossless"}
          # for res <- ["150x150", "1920x1080"] do
          #   {:ok, dest} = Phos.Orbject.S3.put("USR", user.id, "public/profile/#{resolution[res]}")
          #   [hd | tail] = payload |> get_in(["photo"]) |> Enum.reverse()
          #   file_get = HTTPoison.get("https://api.telegram.org/file/bot#{Config.get(:bot_token)}/#{file_get |> get_in(["file_id"])}")
          #   HTTPoison.put(dest, {:file, "https://api.telegram.org/file/bot#{Config.get(:bot_token)}/#{file_get |> get_in(["file_path"])}"})
          # end
          ExGram.send_photo(telegram_id, Phos.Orbject.S3.get!("USR", user.id, "public/profile/lossless"), caption: "Profile picture updated!" <> profile_text_builder(user), parse_mode: "HTML", reply_markup: build_cancel_button())
         else
          _ ->
            IO.inspect("Something went wrong setting picture")
        end
      %{state: "create_orb"} = user_state ->
        media = %{
          access: "public",
          essence: "profile",
          resolution: "lossy",
          count: user_state.data.mediacount
        }
        mediacount = user_state.data.mediacount + 1
        {_prev, user_state} = get_and_update_in(user_state.data.media, &{&1, [media | user_state.data.media]})
        {_prev, user_state} = get_and_update_in(user_state.data.mediacount, &{&1, mediacount})
        StateManager.set_state(telegram_id, user_state)

        ExGram.send_photo(telegram_id, payload |> get_in(["photo"]) |> Enum.reverse() |> List.first() |> get_in(["file_id"]), caption: "Media ##{mediacount - 1} attached!\n" <> orb_creation_preview_builder(user_state.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
        # ExGram.send_photo(telegram_id, payload, caption: "Media attached!\n" <> orb_creation_preview_builder(user_state.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
        # with {:ok, media} <- Phos.Orbject.Structure.apply_media_changeset(%{id: attrs["id"], archetype: "ORB", media: media}) do
        #   ExGram.send_photo(telegram_id, Phos.Orbject.S3.get!("ORB", attrs["id"], "public/profile/lossless"), caption: "Media attached!\n" <> orb_creation_preview_builder(user_state.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
        # end
    end
  end

  # def handle({:message, :post, payload}) do
  #   helps = [
  #     "Test mass send message to all users",
  #   ]
  #   ExGram.send_message(payload |> get_in(["chat", "id"]), Enum.join(helps, "\n"))
  #   {:ok, user} = Phos.Users.get_user_by_telegram(payload |> get_in(["chat", "id"]) |> to_string())

  #   params = %{
  #     "id" => Ecto.UUID.generate(),
  #     "expires_in" => "10000",
  #     "title" => "aikido style",
  #     "inner_title" => "xcape the matrix",
  #     "info" => "ba sing se",
  #     "active" => "true",
  #     "source" => "tele",
  #     "geolocation" => %{"central_geohash" => 623275816486633471}
  #   }

  #   with {:ok, attrs} <- PhosWeb.API.OrbController.orb_constructor(user, send_photoparams),
  #        {:ok, %Phos.Action.Orb{} = orb} <- Phos.Action.create_orb(attrs) do
  #         TN.Collector.add(orb)
  #   end
  #   # case Phos.Action.create_orb() do
  #   #   {:ok, orb} ->

  #   #   {:error, err} -> IO.inspect(err)
  #   # end
  # end

  # ====================
  # CALLBACK QUERY
  # ====================

  # SET LOCATION

  # def handle({:callback_query, %{"data" => "location"} = payload}) do
  #   telegram_id = payload |> get_in(["message", "chat", "id"])
  #   texts = [
  #     "You can set up your home, work and live location",
  #     "Just send your pinned location or live location after hitting the button",
  #   ]
  #   ExGram.send_message(telegram_id, Enum.join(texts, "\n"), reply_markup: build_location_button())
  # end


  def handle({:callback_query, %{"data" => "onboarding"} = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    user_state = StateManager.get_state(telegram_id)
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "onboarding", data: %{}}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.send_message(telegram_id, "What is your email?\n\nPlease provide us with a valid email, you will receive a confirmation email to confirm your registration.", parse_mode: "HTML")
  end

  def handle({:callback_query, %{"data" => "createorb_" <> type } = payload}) when type in ["continue", "restart"] do
    telegram_id = payload |> get_in(["message", "chat", "id"])

    case type do
      "continue" ->
        user_state = StateManager.get_state(telegram_id)
        ExGram.send_message(telegram_id, orb_creation_preview_builder(user_state.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
      "restart" ->
        StateManager.delete_state(telegram_id)
        create_fresh_orb_form(telegram_id)
    end
  end

  # PROFILE - LINK ACCOUNT
  def handle({:callback_query, %{"data" => "link_account" } = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    {:ok, user} = Users.get_user_by_telegram(telegram_id |> to_string())

    case user do
      %{integrations: %{telegram_chat_id: _}} ->
        ExGram.send_message(telegram_id, "You have already linked your telegram account to the Scratchbac App.")
      _ ->
        profilefsm = %Phos.TeleBot.ProfileFSM{state: "link_account"}
        StateManager.set_state(telegram_id, profilefsm)
        ExGram.send_message(telegram_id, "To link your telegram to the Scratchbac App, please type the same email address you used to register on the Scratchbac App.", reply_markup: build_cancel_button())
    end
  end

  # @doc """
  #  Handle callback query for user to complete their profile so they can start posting
  # """
  def handle({:callback_query, %{"data" => "complete_profile_for_post"} = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    {:ok, user} = Users.get_user_by_telegram(telegram_id |> to_string())
    user_state = StateManager.get_state(telegram_id)

    # Set the list of missing fields to state.data
    profile_fields_checklist = %{
      username: not is_nil(user.username),
      profile_picture: user.media,
    }
    # Check if user already set his username
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "finish_profile_to_post", data: %{profile_fields_checklist: profile_fields_checklist}}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.send_message(telegram_id, "Choose a username.\n\n<b>Note: you will not be able to change your username after this set up.</b>", parse_mode: "HTML", reply_markup: build_choose_username_keyboard(payload |> get_in(["message", "chat", "username"])))
  end

  # @doc """
  #   Handle callback query for edit private_profile location to set the location based on the chosen type
  # """
  def handle({:callback_query, %{"data" => "edit_profile_locationtype_" <> type } = payload}) when type in ["home", "work", "live"] do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    text = "Please type your postal code or send your location for #{type} location."

    locationfsm = %Phos.TeleBot.LocationFSM{state: "set_location", data: %{location_type: type}}
    StateManager.set_state(telegram_id, locationfsm)
    ExGram.send_message(telegram_id, text, reply_markup: build_current_location_button())
  end

  # @doc """
  #   Handle callback query for edit profile name, bio, location type prompt, picture
  # """
  def handle({:callback_query, %{"data" => "edit_profile_" <> type} = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    {:ok, user} = Users.get_user_by_telegram(telegram_id |> to_string())
    user_state = StateManager.get_state(telegram_id)

    case type do
      "name" ->
        profilefsm = %Phos.TeleBot.ProfileFSM{state: "edit_profile_name"}
        StateManager.set_state(telegram_id, profilefsm)
        ExGram.send_message(telegram_id, "What shall we call you?", parse_mode: "HTML" , reply_markup: build_cancel_button())
      "bio" ->
        profilefsm = %Phos.TeleBot.ProfileFSM{state: "edit_profile_bio"}
        StateManager.set_state(telegram_id, profilefsm)
        ExGram.send_message(telegram_id, "Let's setup your bio. Share your hobbies or skills", parse_mode: "HTML" , reply_markup: build_cancel_button())
      "location" ->
        ExGram.send_message(telegram_id, "You can set up your home, work and live location\nJust send your pinned location or live location after hitting the button", reply_markup: build_location_button())
      "picture" ->
        profilefsm = %Phos.TeleBot.ProfileFSM{state: "set_profile_picture"}
        StateManager.set_state(telegram_id, profilefsm)
        ExGram.send_message(telegram_id, "Spice up your profile with a profile picture! Send a picture.", parse_mode: "HTML", reply_markup: build_cancel_button())
    end
  end

  def handle({:callback_query, %{"data" => "help_" <> type} = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    case type do
      "guidelines" -> ExGram.send_message(telegram_id, "Here's some details about our guidelines.")
      "about" -> ExGram.send_message(telegram_id, "Here's some details about us.")
      "feedback" -> ExGram.send_message(telegram_id, "You can provide your feedback to our admins directly at @Scratchbac_Admin")
    end
  end

  # ====================
  # INLINE QUERY
  # ====================

  def handle({:inline_query, %{"query" => type} = payload}) when type in ["home", "work", "live"] do
    telegram_id = payload |> get_in(["from", "id"])
    query_id = payload |> get_in(["id"])
    {:ok, user} = Users.get_user_by_telegram(telegram_id |> to_string())

    if user.private_profile do
      case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == type end) do
        nil -> ExGram.send_message(telegram_id, update_location_text_builder(%{location_type: type}), parse_mode: "HTML", reply_markup: build_location_specific_button(type))
        # ExGram.send_message(telegram_id, "Please set your #{type} location first.")
        %{geohash: geohash} ->
          %{data: orbs} = Phos.Action.orbs_by_geohashes({[:h3.parent(geohash, 8)], user.id}, 1)
          build_inlinequery_orbs(orbs)
          |> then(fn ans -> ExGram.answer_inline_query(to_string(query_id), ans) end)
      end
    else
      "Not set"
    end
  end

  # ====================
  # LOCATION MESSAGE
  # ====================

  def handle({:location, %{"location" => %{"latitude" => lat, "longitude" => lon}} = payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    user_state = StateManager.get_state(telegram_id)
    if user_state do
      case user_state.state do
        "set_location" ->
          update_user_location(telegram_id, {lat, lon}, desc = Phos.Mainland.World.locate(:h3.from_geo({lat, lon}, 11)))
        "create_orb" ->
          user_state = StateManager.get_state(telegram_id)
          {_prev, user_state} = get_and_update_in(user_state.data.geolocation.central_geohash, &{&1, :h3.from_geo({lat, lon}, 10)} )
          {_prev, user_state} = get_and_update_in(user_state.data.location_type, &{&1, :live} )
          StateManager.set_state(telegram_id, user_state)
          ExGram.send_message(telegram_id, orb_creation_preview_builder(user_state.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
        _ ->
          ExGram.send_message(telegram_id, "Your location not set.")
      end
    end
  end

  # def handle({:bot_message, to, %Phos.Action.Orb{} = orb}, _context) do
  #   text = case orb.media do
  #     true ->
  #       url = Phos.Orbject.S3.get!("ORB", orb.id, "public/banner/lossless")
  #       "#{url}\n\n#{orb_telegram_orb_builder(orb)}"
  #     _ -> orb_telegram_orb_builder(orb)
  #   end
  #   ExGram.send_message(to, text, reply_markup: build_orb_notification_button(orb))
  # end

  def handle({_, _}), do: []
  def handle({_, _, _}), do: []

  # ====================
  # MENU BUTTONS
  # ====================

  def build_registration_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
      %ExGram.Model.InlineKeyboardButton{
        text: "Register to ScratchBac",
        login_url: %ExGram.Model.LoginUrl{
          url: Config.get(:callback_url),
          forward_text: "Sample text",
          bot_username: Config.get(:bot_username),
          request_write_access: true
        },
      }
    ]]}
  end

  def build_onboarding_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
      %ExGram.Model.InlineKeyboardButton{
        text: "Register",
        callback_data: "onboarding"
      }
    ]]}
  end

  def complete_profile_for_post_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
      %ExGram.Model.InlineKeyboardButton{
        text: "Complete Profile",
        callback_data: "complete_profile_for_post"
      }
    ]]}
  end

  def build_menu_keyboard() do
    %ExGram.Model.ReplyKeyboardMarkup{resize_keyboard: true, keyboard:  [
      [
        %ExGram.Model.KeyboardButton{text: "🔭 Latest Posts"},
      ],
      [
        %ExGram.Model.KeyboardButton{text: "👤 Profile"},
        %ExGram.Model.KeyboardButton{text: "❓ Help"},
      ]
    ]}
  end

  defp build_choose_username_keyboard(username) do
    %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: true, resize_keyboard: true, keyboard:  [
      [
        %ExGram.Model.KeyboardButton{text: "#{username}"},
      ]
    ]}
  end

  defp create_fresh_orb_form(telegram_id) do
    {:ok, user} = Phos.Users.get_user_by_telegram(telegram_id |> to_string())
    createorbfsm = %Phos.TeleBot.CreateOrbFSM{state: "create_orb", data: %{inner_title: "", media: %{}, mediacount: 1, location_type: "", geolocation: %{central_geohash: ""}}}
    StateManager.set_state(telegram_id, createorbfsm)
    ExGram.send_message(telegram_id, orb_creation_desc_builder(createorbfsm.data), parse_mode: "HTML", reply_markup: build_orb_create_keyboard_button())
  end

  def build_settings_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Edit Name", callback_data: "edit_profile_name"},
        %ExGram.Model.InlineKeyboardButton{text: "Edit Bio", callback_data: "edit_profile_bio"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "Set Location", callback_data: "edit_profile_location"},
        %ExGram.Model.InlineKeyboardButton{text: "Edit Picture", callback_data: "edit_profile_picture"},
      ]
      ]}
  end

  def build_link_account_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Link Account", callback_data: "link_account"},
      ]
      ]}
  end

  def build_help_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Guidelines", callback_data: "help_guidelines"},
        %ExGram.Model.InlineKeyboardButton{text: "About", callback_data: "help_about"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "Contact Us", callback_data: "help_feedback"},
      ]
      ]}
  end

  defp build_location_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
      %ExGram.Model.InlineKeyboardButton{text: "Home", callback_data: "edit_profile_locationtype_home"},
      %ExGram.Model.InlineKeyboardButton{text: "Work", callback_data: "edit_profile_locationtype_work"},
      %ExGram.Model.InlineKeyboardButton{text: "Live", callback_data: "edit_profile_locationtype_live"},
    ]]}
  end

  defp build_location_specific_button(loc_type) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
      %ExGram.Model.InlineKeyboardButton{text: "Set #{loc_type}", callback_data: "edit_profile_locationtype_#{String.downcase(loc_type)}"},
    ]]}
  end

  defp build_current_location_button() do
    %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: true, resize_keyboard: true, keyboard:  [[
      %ExGram.Model.KeyboardButton{text: "Send Current Location", request_location: true}
    ]]}
  end

  defp build_createorb_location_button() do
    %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: true, resize_keyboard: true, keyboard:  [[
      %ExGram.Model.KeyboardButton{text: "🏡 Home"},
      %ExGram.Model.KeyboardButton{text: "🏢 Work"},
      %ExGram.Model.KeyboardButton{text: "📍 Live", request_location: true}
    ]]}
  end

  defp build_existing_post_creation_inline_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Continue", callback_data: "createorb_continue"},
        %ExGram.Model.InlineKeyboardButton{text: "Restart", callback_data: "createorb_restart"},
      ]
      ]}
  end

  defp build_latest_posts_inline_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Home", switch_inline_query_current_chat: "home"},
        %ExGram.Model.InlineKeyboardButton{text: "Work", switch_inline_query_current_chat: "work"},
        %ExGram.Model.InlineKeyboardButton{text: "Live", switch_inline_query_current_chat: "live"},
      ]
      ]}
  end

  defp build_preview_inline_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Edit Post", callback_data: "createorb_edit"},
        %ExGram.Model.InlineKeyboardButton{text: "Confirm Post", callback_data: "createorb_confirm"},
      ]
      ]}
  end

  def build_cancel_button() do
    %ExGram.Model.ReplyKeyboardMarkup{resize_keyboard: true, keyboard:  [[
      %ExGram.Model.KeyboardButton{text: "❌ Cancel"}
    ]]}
  end

  defp build_orb_notification_button(orb) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        # %ExGram.Model.InlineKeyboardButton{text: "💬 Message User", callback_data: "orb_message_user#{orb.id}"},
        %ExGram.Model.InlineKeyboardButton{text: "Open on Web", url: "https://nyx.scrb.ac/orb/#{orb.id}"},
      ]
    ]}
  end

  defp build_orb_create_keyboard_button() do
    %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: false, resize_keyboard: true, keyboard:  [
      [
        %ExGram.Model.KeyboardButton{text: "📎 Media"},
        %ExGram.Model.KeyboardButton{text: "📍 Location"},
      ],
      [
        %ExGram.Model.KeyboardButton{text: "❌ Cancel"},
        %ExGram.Model.KeyboardButton{text: "✈️ Post"},
      ]
    ]}
  end

  defp build_inlinequery_orbs(orbs) do
    orbs
    |> Enum.map(fn (orb)->
      article = %ExGram.Model.InlineQueryResultArticle{}
      %{article |
          id: orb.id,
          type: "article",
          title: orb.title,
          description: orb.payload.inner_title,
          input_message_content: %ExGram.Model.InputTextMessageContent{ %ExGram.Model.InputTextMessageContent{} | message_text: orb_telegram_orb_builder(orb), parse_mode: "HTML" },
          # reply_markup: build_orb_notification_button(orb),
          url: "https://nyx.scrb.ac/orb/#{orb.id}}",
          thumbnail_url: "https://picsum.photos/200/300", #Phos.Orbject.S3.get!("ORB", orb.id, "public/banner/lossless"),
        } end)
  end

  defp create_user(%{"id" => id} = params) do
    options =
      Map.merge(params, %{
        "sub" => id,
        "provider" => "telegram"
      })

    case Phos.Users.from_auth(options) do
      {:ok, _user} ->
        # ExGram.send_message(id, "(To be removed) Registered successfully", reply_markup: Phos.TeleBot.build_menu_keyboard())
        nil
      {:error, msg} ->
        IO.inspect("Error occured registering \n #{msg}")
        # ExGram.send_message(id, "", reply_markup: Phos.TeleBot.build_menu_keyboard())
    end
  end

  defp registration_menu(payload) do
    texts = [
      "Hi",
      "Welcome to ScratchBac Telegram Bot.",
      "You can posting register and posting an orb and join with the community.",
      "To register click the link below",
      "\n",
      "Thanks.",
      "ScratchBac Team."
    ]

    # answer(context, Enum.join(texts, "\n"), reply_markup: build_registration_button())
    ExGram.send_message(payload |> get_in(["chat", "id"]), Enum.join(texts, "\n"), reply_markup: build_registration_button())
  end

  defp main_menu(payload) do
    ExGram.send_photo(payload |> get_in(["chat", "id"]), "https://static.wixstatic.com/media/551811_5a936d29f2b14428aebd17ab9afda722~mv2.jpeg/v1/fill/w_740,h_555,al_c,q_85,usm_0.66_1.00_0.01,enc_auto/551811_5a936d29f2b14428aebd17ab9afda722~mv2.jpeg", caption: main_menu_text_builder(%{}), parse_mode: "HTML", reply_markup: build_menu_keyboard())
  end

  defp onboarding_text(payload) do
    ExGram.send_message(payload |> get_in(["chat", "id"]), "We have so many features here and can't wait for you to join us but you need to be verified to use them.\n\n<u>Please click on the button below to register an account with us!</u>\n\n<i>Note: If you have already registered, do check your email or register again</i>", parse_mode: "HTML", reply_markup: build_onboarding_button())
  end

  defp update_user_location(telegram_id, geo, desc) do
    type =
      case StateManager.get_state(telegram_id) do
        %{data: %{location_type: type}} -> type
        _ -> nil
      end
    validate_user_update_location(type, telegram_id, geo, desc)
  end

  defp validate_user_update_location(nil, telegram_id, _, _), do: ExGram.send_message(telegram_id, "You must set your location type")
  defp validate_user_update_location(type, telegram_id, geo, desc) do
    {:ok, %{private_profile: priv} = user} = Users.get_user_by_telegram(to_string(telegram_id))
    geos = case priv do
      nil ->
        []
      _ ->
        Map.get(priv, :geolocation, []) |> Enum.map(&Map.from_struct(&1) |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, to_string(k), v) end)) |> Enum.reduce([], fn loc, acc ->
          case Map.get(loc, "id") == type do
            true -> acc
            _ -> [loc | acc]
          end
        end)
    end

    # Clean up state
    StateManager.delete_state(telegram_id)

    case Phos.Users.update_territorial_user(user, %{private_profile: %{user_id: user.id, geolocation: [%{"id" => type, "geohash" => :h3.from_geo(geo, 11), "location_description" => desc} | geos]}}) do
      {:ok, user} ->
        ExGram.send_message(telegram_id, "Your #{type} location is set" <> profile_text_builder(user), reply_markup: build_settings_button(), reply_markup: remove_keyboard())

        # Send last 10 messages to user
        # %{data: orbs} = Phos.Action.orbs_by_geohashes({[:h3.from_geo(geo, 8)], user.id}, 1)
        # build_inlinequery_orbs(orbs)
        # |> then(fn ans -> ExGram.answer_inline_query(telegram_id, ans) end)

        # Phos.Action.orbs_by_geohashes([:h3.from_geo(geo, 8)])
        # |> build_inlinequery_orbs()
        # |> then(fn ans -> ExGram.answer_inline_query(telegram_id, ans) end)
          # case orb.media do
          #   true ->
          #     IO.inspect("ORB: #{orb.title}")
          #       text = orb_telegram_orb_builder(orb) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
          #       ExGram.send_photo(context.update |> elem(1) |> get_in(["chat", "id"]), parse_mode: "HTML", caption: text, photo: "https://s3.ap-southeast-1.amazonaws.com/orbistertius/USR/b556571a-362e-4017-9894-f1eed0b39794/public/profile/lossless?ContentType=application%2Foctet-stream&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIATRBGRJXXLGYOVAYO%2F20230615%2Fap-southeast-1%2Fs3%2Faws4_request&X-Amz-Date=20230615T025401Z&X-Amz-Expires=88888&X-Amz-SignedHeaders=host&X-Amz-Signature=20963f4e00ce672bdd8547c8fc72a98c383e8f4ec2bbb9d2fa54c2219dbdc9d3", reply_markup: build_orb_notification_button())
          #     _ ->
          #       IO.inspect("ORB no PIC: #{orb.title}}")
          #       text = orb_telegram_orb_builder(orb) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
          #       ExGram.send_message(context.update |> elem(1) |> get_in(["chat", "id"]), text, parse_mode: "HTML", reply_markup: build_orb_notification_button())
          # end
      _ -> ExGram.send_message(telegram_id, "Your #{type} location is not set.", reply_markup: build_menu_keyboard())
    end
  end

  def remove_keyboard() do
    %ExGram.Model.ReplyKeyboardRemove{remove_keyboard: true}
  end

  def dispatch_messages(events) do
    Enum.map(events, fn %{chat_id: chat_id, orb: orb} ->
      # IO.inspect(orb)
      ExGram.send_message(chat_id, orb_telegram_orb_builder(orb), parse_mode: "HTML", reply_markup: build_orb_notification_button(orb))
    end)
  end

  defp get_location_from_postal_json(postal) do
    with {:ok, body} <- File.read("../HeimdallrNode/resources/postal_codes-JUN-2023.json"),
         {:ok, json} <- Poison.decode(body) do
            if json[postal] do
              json[postal]
            else
              nil
            end
    end
  end

  # ====================
  # MARKDOWN
  # ====================

  defp main_menu_text_builder(assigns) do
    ~H"""
    Welcome to the ScratchBac Telegram Bot!

    <u>Announcements</u>
      - Telegram Bot is now live!
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp help_text_builder(assigns) do
    ~H"""
    Here is your inline command help:
      1. /start - To start using the bot

      Additional information
      - /help - Show this help
      - /post - Post something
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp onboarding_text_builder(assigns) do
    ~H"""
    Welcome to the ScratchBac Telegram Bot!

    Set your location now to hear what's happening around you! You need to /register to use all our features (/profile, /post).
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp incomplete_profile_text_builder(assigns) do
    ~H"""
    Hold on! Are you a robot? Please complete your profile before posting.

    You still have not set your: <%= if not @username do %>Username<% end %><%= if not @profile_picture do %> Profile Picture<% end %>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp latest_posts_text_builder(assigns) do
    ~H"""
    <b>Which posts would you like to view</b>

    You can also use the /post command to post something.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp update_location_text_builder(assigns) do
    ~H"""
    <b>You have not set your <%= @location_type %> location</b>

    Please update your location by clicking the button below.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp orb_creation_desc_builder(assigns) do
    ~H"""
    <b>Type and send your post description below.</b> <i>(max 300 characters)</i>

    Here's an example:
    📢 : Open Jio SUPPER! Hosting a prata night this Saturday @ 8pm, anyone can come!
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp orb_creation_media_builder(assigns) do
    ~H"""
    <b>Attach a media to go along with your post.</b> <i>(pictures, gifs, videos)</i>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp orb_creation_location_builder(assigns) do
    ~H"""
    <b>Where should we send this post to?</b>

    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp orb_creation_preview_builder(assigns) do
    ~H"""
    <b>Preview your post</b> <i>(You can edit your post)</i>

    📍 <b>Posting to: </b><%= to_string(@location_type) %>
    📋 <b>What's happening today?</b>
    <%= @inner_title %>
    <%!-- 💚 <b>Info:</b> <%= @info %> --%>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp orb_telegram_orb_builder(assigns) do
    ~H"""
    📋 <b>Inner Title:</b> <%= @payload.inner_title %>

    👤 From:
    <%!-- 💚 <b>Info:</b> <%= @payload.info %> --%>
    <%!-- 💜 <b>By:</b> <% if is_nil(@initiator.username), do: %><a href={"tg://user?id=#{@telegram_user["id"]}"}>@<%= @telegram_user["username"] %></a> <% , else: %> <%= @initiator.username %> --%>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp profile_text_builder(assigns) do
    ~H"""
    <%!-- 👤 User: <a href={"tg://user?id=#{@telegram_user}"}>@<%= @telegram_user["username"] %></a> --%>
    <%!-- 👤 User: <%= @username %> --%>

    🔸Name: <%= @public_profile.public_name %>
    🔸Bio: <%= @public_profile.bio %>
    🔸Join Date: <%= @inserted_at |> DateTime.from_naive!("UTC") |> Timex.format("{D}-{0M}-{YYYY}") |> elem(1) %>
    🔸Locations:
        - Home: <%= get_location_desc_from_user(assigns, "home") %>
        - Work: <%= get_location_desc_from_user(assigns, "work") %>

    🔗Share your profile:
    <%= PhosWeb.Endpoint.url %>/<%= @username %>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def get_location_desc_from_user(user, type) do
    if user.private_profile do
      case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == type end) do
        nil -> "Not set"
        %{location_description: desc} -> desc
      end
    else
      "Not set"
    end
  end
end
