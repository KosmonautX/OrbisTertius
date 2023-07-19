defmodule Phos.TeleBot.Core do
  use Phoenix.Component
  import PhosWeb.Endpoint, only: [url: 0]
  use PhosWeb, :html

  require Logger
  @bot :phos_telebot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  alias Phos.{Users, Orbject, Action}
  alias Phos.Users.User
  alias Phos.TeleBot.{Config, StateManager, CreateOrb, ProfileFSM}
  alias Phos.TeleBot.Core.{UserProfile}
  alias Phos.TeleBot.Components.{Button, Template}

  command("start", description: "Start using the Scratchbac bot")
  command("menu", description: "Show the main menu")
  command("help", description: "Show the help menu")
  command("post", description: "Post something")
  command("register", description: "Register an account")
  command("profile", description: "View your profile")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  def handle({:message, :start, %{"chat" => %{"id" => telegram_id}} = payload}) do
    start_menu(telegram_id)
  end

  def handle({:message, :menu, %{"chat" => %{"id" => telegram_id}} = payload}) do
    main_menu(telegram_id)
  end

  def handle({:message, :help, %{"chat" => %{"id" => telegram_id}} = payload}) do
    ExGram.send_message(telegram_id, Template.help_text_builder(%{}))
  end

  @doc """
  Handle messages as requested by menus (Postal codes, email addresses, createorb inner_title etc.)
  """
  def handle({:message, :text, %{"chat" => %{"id" => telegram_id}, "text" => text} = payload}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id),
         {:ok, user_state} <- StateManager.get_state(telegram_id) do
        message_route(user_state, [user: user, telegram_id: telegram_id, text: text])
      else
        _ ->
          error_fallback(telegram_id)
      end
  end

  # @doc """
  # Check if meets all necessary profile fields to post or user has a post ongoing, prompt to continue editing or reset
  # """
  def handle({:message, :post, %{"chat" => %{"id" => telegram_id}} = payload}) do
    post_orb(telegram_id)
  end

  def handle({:message, :register, %{"chat" => %{"id" => telegram_id}} = payload}) do
    case get_user_by_telegram(telegram_id) do
      {:ok, %{integrations: %{telegram_chat_id: _}, confirmed_at: date}} when not is_nil(date) ->
        ExGram.send_message(telegram_id, "You have completed registration!")
      {:ok, %{integrations: %{telegram_chat_id: nil}} = user} ->
        ExGram.send_message(telegram_id, "You already have an account with us. Would you like to link your telegram to your Scratchbac account?",
          reply_markup: Button.build_link_account_button())
      {:ok, %{confirmed_at: nil}} ->
        ExGram.send_message(telegram_id, "You have not confirmed your email. Please check your inbox and follow the instructions to link your account.\n\n<u>Did not receive any emails? Do /register again </u>", parse_mode: "HTML")
      _ ->
        onboarding_register_text(telegram_id)
    end
  end

  def handle({:message, :profile, %{"chat" => %{"id" => telegram_id}} = payload}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id) do
      UserProfile.open_user_profile(user)
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  def handle({:photo, %{"chat" => %{"id" => telegram_id}} = payload}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id),
         {:ok, %{branch: branch}} <- StateManager.get_state(telegram_id),
         {:ok, %{message_id: message_id}} <- ExGram.send_message(telegram_id, "Setting photo...") do
      case branch do
        %{state: "picture", path: "self/update"} ->
          UserProfile.set_picture(user, payload)
          UserProfile.open_user_profile(user)
          StateManager.delete_state(telegram_id)
        %{state: "media", path: "orb/create"} ->
          CreateOrb.set_picture(user, payload)
        err -> error_fallback(telegram_id, err)
      end
      ExGram.delete_message(telegram_id, message_id)
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  # ====================
  # CALLBACK QUERY
  # ====================

  def handle({:callback_query, %{"data" => "start_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}} = payload}) do
    case type do
      "mainmenu" <> message_id ->
        main_menu(telegram_id, message_id)
      "faq" <> message_id ->
        faq(telegram_id, message_id)
      "feedback" <> message_id ->
        feedback(telegram_id, message_id)
    end
  end

  def handle({:callback_query, %{"data" => "onboarding", "message" => %{"chat" => %{"id" => telegram_id}}} = payload}) do
    with {:ok, user_state} <- StateManager.get_state(telegram_id) do
      profilefsm = %Phos.TeleBot.ProfileFSM{state: "onboarding", data: %{}}
      StateManager.set_state(telegram_id, profilefsm)
      ExGram.send_message(telegram_id, "What is your email?\n\nPlease provide us with a valid email, you will receive a confirmation email to confirm your registration.", parse_mode: "HTML")
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  def handle({:callback_query, %{"data" => "menu_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}} = payload}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id) do
      case type do
        "post" ->
          post_orb(telegram_id)
        "openprofile" <> message_id ->
          UserProfile.open_user_profile(user, message_id)
        "latestposts" <> message_id ->
          open_latest_posts(user, message_id)
      end
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  def handle({:callback_query, %{"data" => "createorb_back_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}} = payload})
      when type in ["description", "location", "media"] do
    with {:ok, user} <- get_user_by_telegram(telegram_id),
         {:ok, %{branch: branch}} <- StateManager.get_state(telegram_id) do
      CreateOrb.transition(branch, type)
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  def handle({:callback_query, %{"data" => "createorb_" <> type, "message" => %{"chat" => %{"id" => telegram_id}} } = payload})
    when type in ["location_home", "location_work", "location_live", "description", "location", "media", "preview", "post"] do
    with {:ok, user} <- get_user_by_telegram(telegram_id),
         {:ok, %{branch: branch}} <- StateManager.get_state(telegram_id) do
      case {type, branch} do
        {"location_home", %{path: "orb/create", state: "location"}} ->
          CreateOrb.set_location(branch, "home")
        {"location_work", %{path: "orb/create", state: "location"}} ->
          CreateOrb.set_location(branch, "work")
        {"location_live", %{path: "orb/create", state: "location"}} ->
          ExGram.send_message(branch.telegram_id, "Send your location with the 📎 button below.", parse_mode: "HTML", reply_markup: Button.build_current_location_button())
        {"preview", %{path: "orb/create"}} ->
          CreateOrb.preview(branch)
        {"post", %{path: "orb/create"}} ->
          CreateOrb.post(branch, user)
      end
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  # PROFILE - LINK ACCOUNT
  def handle({:callback_query, %{"data" => "link_account", "message" => %{"chat" => %{"id" => telegram_id}}} = payload}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id) do
      case user do
        %{integrations: %{telegram_chat_id: _}} ->
          ExGram.send_message(telegram_id, "You have already linked your telegram account to the Scratchbac App.")
        _ ->
          profilefsm = %Phos.TeleBot.ProfileFSM{state: "link_account"}
          StateManager.set_state(telegram_id, profilefsm)
          ExGram.send_message(telegram_id, "To link your telegram to the Scratchbac App, please type the same email address you used to register on the Scratchbac App.", reply_markup: Button.build_cancel_button())
      end
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  # @doc """
  #  Handle callback query for user to complete their profile so they can start posting
  # """
  def handle({:callback_query, %{"data" => "complete_profile_for_post", "message" => %{"chat" => %{"id" => telegram_id}}} = payload}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id),
         {:ok, user_state} <- StateManager.get_state(telegram_id) do
           # Check if user already set his username
      profilefsm = %Phos.TeleBot.ProfileFSM{state: "complete_profile_to_post"}
      StateManager.set_state(telegram_id, profilefsm)
      ExGram.send_message(telegram_id, Template.edit_profile_username_text_builder(%{}),
        parse_mode: "HTML", reply_markup: Button.build_choose_username_keyboard(payload |> get_in(["message", "chat", "username"])))
      else
        err -> error_fallback(telegram_id, err)
      end
  end

  # @doc """
  #   Handle callback query for edit private_profile location to set the location based on the chosen type
  # """
  def handle({:callback_query, %{"data" => "edit_profile_locationtype_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}} = payload}) when type in ["home", "work", "live"] do
    UserProfile.edit_locationtype_prompt(telegram_id, type)
  end

  # @doc """
  #   Handle callback query for edit profile name, bio, location type prompt, picture
  # """
  def handle({:callback_query, %{"data" => "edit_profile_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}} = payload}) do
    case type do
      "name" <> message_id ->
        UserProfile.edit_name_prompt(telegram_id, message_id)
      "bio" <> message_id ->
        UserProfile.edit_bio_prompt(telegram_id, message_id)
      "location" <> message_id ->
        UserProfile.edit_location_prompt(telegram_id, message_id)
      "picture" <> message_id ->
        UserProfile.edit_picture_prompt(telegram_id, message_id)
    end
  end

  # ====================
  # INLINE QUERY
  # ====================
  def handle({:inline_query, %{"id" => query_id, "query" => "myposts", "from" => %{"id" => telegram_id}} = payload}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id) do
      %{data: orbs} = Phos.Action.orbs_by_initiators([user.id], 1)
      build_inlinequery_orbs(orbs)
      |> then(fn ans -> ExGram.answer_inline_query(to_string(query_id), ans) end)
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  def handle({:inline_query, %{"id" => query_id, "query" => type, "from" => %{"id" => telegram_id}} = payload}) when type in ["home", "work", "live"] do
    with {:ok, user} <- get_user_by_telegram(telegram_id) do
      if user.private_profile do
        case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == type end) do
          nil -> ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: type}),
            parse_mode: "HTML", reply_markup: Button.build_location_specific_button(type))
          %{geohash: geohash} ->
            %{data: orbs} = Phos.Action.orbs_by_geohashes({[:h3.parent(geohash, 8)], user.id}, limit: 12)
            build_inlinequery_orbs(orbs)
            |> then(fn ans -> ExGram.answer_inline_query(to_string(query_id), ans) end)
        end
      else
        "Not set"
      end
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  # ====================
  # LOCATION MESSAGE
  # ====================

  def handle({:location, %{"location" => %{"latitude" => lat, "longitude" => lon}, "chat" => %{"id" => telegram_id}} = payload}) do
    with {:ok, %{branch: branch } = user_state} <- StateManager.get_state(telegram_id) do
      case branch do
        %{path: "self/update", state: "location"} ->
          ProfileFSM.update_user_location(telegram_id, {lat, lon}, desc = Phos.Mainland.World.locate(:h3.from_geo({lat, lon}, 11)))
          |> UserProfile.open_user_profile()
        %{path: "orb/create", state: "location"} ->
          CreateOrb.set_location(branch, "live", [latlon: {lat, lon}])
        _ ->
          ExGram.send_message(telegram_id, "Your location not set.")
      end
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  # Catch any other messages and do nothing
  def handle({_, _}), do: []
  def handle({_, _, _}), do: []

  def get_user_by_telegram(telegram_id), do: Users.get_user_by_telegram(telegram_id |> to_string())

  defp build_inlinequery_orbs(orbs) do
    orbs
    |> Enum.map(fn (orb)->
      article = %ExGram.Model.InlineQueryResultArticle{}
      %{article |
          id: orb.id,
          type: "article",
          title: orb.title,
          description: orb.payload.inner_title,
          input_message_content: %ExGram.Model.InputTextMessageContent{ %ExGram.Model.InputTextMessageContent{} |
            message_text: Template.orb_telegram_orb_builder(orb), parse_mode: "HTML" },
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
      {:ok, user} ->
        user
      {:error, msg} ->
        IO.inspect("Error occured registering \n #{msg}")
    end
  end

  defp start_menu(telegram_id), do: start_menu(telegram_id, nil)
  defp start_menu(telegram_id, message_id) do
    start_main_menu_check_and_register(telegram_id)
    with {:ok, %{confirmed_at: date} = user} when not is_nil(date) <- get_user_by_telegram(telegram_id) do
      start_menu_text(telegram_id, message_id)
    else
      _ ->
        onboard_text(telegram_id)
    end
  end

  defp start_menu_text(telegram_id, message_id) do
    {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id,
      Template.start_menu_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id,
      reply_markup: Button.build_start_inlinekeyboard(message_id))
  end

  defp main_menu(telegram_id), do: main_menu(telegram_id, nil)
  defp main_menu(telegram_id, message_id) do
    start_main_menu_check_and_register(telegram_id)
    with {:ok, %{confirmed_at: date} = user} when not is_nil(date) <- get_user_by_telegram(telegram_id) do
      main_menu_text(telegram_id, message_id)
    else
      _ ->
        onboard_text(telegram_id)
    end
  end

  defp main_menu_text(telegram_id), do: main_menu_text(telegram_id, nil)
  defp main_menu_text(telegram_id, ""), do: main_menu_text(telegram_id, nil)
  defp main_menu_text(telegram_id, nil) do
    {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id,
      Template.main_menu_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id, reply_markup: Button.build_menu_inlinekeyboard(message_id))
  end
  defp main_menu_text(telegram_id, message_id) do
    ExGram.edit_message_text(Template.main_menu_text_builder(%{}), chat_id: telegram_id, message_id: message_id |> String.to_integer(),
      parse_mode: "HTML", reply_markup: Button.build_menu_inlinekeyboard(message_id))
  end

  defp faq(telegram_id), do: faq(telegram_id, nil)
  defp faq(telegram_id, ""), do: faq(telegram_id, nil)
  defp faq(telegram_id, nil) do
    {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id,
      Template.faq_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id,
      reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end
  defp faq(telegram_id, message_id) do
    ExGram.edit_message_text(Template.faq_text_builder(%{}), chat_id: telegram_id, message_id: message_id |> String.to_integer(),
      reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end

  defp feedback(telegram_id), do: feedback(telegram_id, nil)
  defp feedback(telegram_id, ""), do: feedback(telegram_id, nil)
  defp feedback(telegram_id, nil) do
    {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id,
      Template.feedback_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id,
      reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end
  defp feedback(telegram_id, message_id) do
    ExGram.edit_message_text(Template.feedback_text_builder(%{}), chat_id: telegram_id, message_id: message_id |> String.to_integer(),
      reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end

  defp onboard_text(telegram_id) do
    {:ok, user} = get_user_by_telegram(telegram_id)
    {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id,
      Template.onboarding_location_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id,
      reply_markup: Button.build_location_button(user, message_id))
  end

  defp start_main_menu_check_and_register(telegram_id) do
    with {:user_exist, true} <- {:user_exist, Users.telegram_user_exists?(telegram_id)} do
        telegram_id
    else
      {:user_exist, false} ->
        user = create_user(%{"id" => telegram_id})
        telegram_id

      {:user, {:ok, user}} ->
        telegram_id
    end
  end

  defp onboarding_register_text(telegram_id) do
    ExGram.send_message(telegram_id, Template.not_yet_registered_text_builder(%{}), parse_mode: "HTML",
    reply_markup: Button.build_onboarding_register_button())
  end

  def error_fallback(telegram_id, err) do
    IO.inspect("Error: #{inspect(err)}")
    error_fallback(telegram_id)
  end
  def error_fallback(telegram_id) do
    StateManager.delete_state(telegram_id)
    ExGram.send_message(telegram_id, Template.fallback_text_builder(%{}), parse_mode: "HTML")
    main_menu(telegram_id)
  end

  def dispatch_messages(events) do
    IO.inspect("im dispatching")
    IO.inspect(events)
    Enum.map(events, fn %{chat_id: chat_id, orb: orb} ->
      text = case orb.media do
        true ->
          ExGram.send_photo(chat_id, "https://media.cnn.com/api/v1/images/stellar/prod/191212182124-04-singapore-buildings.jpg?q=w_2994,h_1996,x_3,y_0,c_crop",
            caption: Template.orb_telegram_orb_builder(orb), parse_mode: "HTML",
            reply_markup: Button.build_orb_notification_button(orb))
          # ExGram.send_photo(chat_id, Phos.Orbject.S3.get!("ORB", orb.id, "public/banner/lossless"),
          #   caption: Template.orb_telegram_orb_builder(orb), parse_mode: "HTML",
          #   reply_markup: Button.build_orb_notification_button(orb))
        _ ->
          ExGram.send_message(chat_id, Template.orb_telegram_orb_builder(orb), parse_mode: "HTML",
            reply_markup: Button.build_orb_notification_button(orb))
      end
      ExGram.send_message(chat_id, text, parse_mode: "HTML", reply_markup: Button.build_orb_notification_button(orb))
    end)
  end

  def get_location_from_postal_json(postal) do
    with {:ok, body} <- File.read("../HeimdallrNode/resources/postal_road_13_07_2023.json"),
         {:ok, json} <- Poison.decode(body) do
            if json[postal] do
              json[postal]
            else
              nil
            end
    end
  end

  defp open_latest_posts(user), do: open_latest_posts(user, nil)
  defp open_latest_posts(user, ""), do: open_latest_posts(user, nil)
  defp open_latest_posts(%{integrations: %{telegram_chat_id: telegram_id}} = user, nil) do
    ExGram.send_message(telegram_id, Template.latest_posts_text_builder(user),
      parse_mode: "HTML", reply_markup: Button.build_latest_posts_inline_button())
  end
  defp open_latest_posts(%{integrations: %{telegram_chat_id: telegram_id}} = user, message_id) do
    ExGram.edit_message_text(Template.latest_posts_text_builder(user), chat_id: telegram_id,
      message_id: message_id |> String.to_integer(), parse_mode: "HTML", reply_markup: Button.build_latest_posts_inline_button(message_id |> String.to_integer()))
  end

  defp post_orb(telegram_id) do
    {:ok, user} = get_user_by_telegram(telegram_id)
    case user do
      %User{confirmed_at: nil} ->
        onboarding_register_text(telegram_id)
      %User{username: nil} ->
        ExGram.send_message(telegram_id, Template.incomplete_profile_text_builder(%{}),
          parse_mode: "HTML", reply_markup: Button.complete_profile_for_post_button())
      %User{media: false} ->
        with {:ok, user_state} <- StateManager.get_state(telegram_id) do
          # user_state = struct(ProfileFSM, Map.from_struct(%ProfileFSM{telegram_id: telegram_id, state: "picture", path: "self/update",
          #   data: %{return_to: "post"}, metadata: %{last_active: DateTime.utc_now() |> DateTime.to_unix()}}))
          case Fsmx.transition(user_state, "picture") do
            {:ok, user_state} ->
              ExGram.send_message(telegram_id, "Almost there! You need to set your user profile picture first.\n\n<i>(Use the 📎 button to attach image)</i>",
                parse_mode: "HTML")
              StateManager.set_state(telegram_id, user_state)
            {:error, err} ->
              error_fallback(telegram_id, err)
          end
        else
          err -> error_fallback(telegram_id, err)
        end
      %User{confirmed_at: _date, media: true, username: _username} ->
        CreateOrb.create_fresh_orb_form(telegram_id)
      err -> error_fallback(telegram_id, err)
    end
  end

  def message_route(%{branch: branch} = user_state, opts) do
    user = opts[:user]
    telegram_id = opts[:telegram_id]
    text = opts[:text]
    case branch do
      %{state: "location", path: "self/update"} ->
        {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id, "Checking location...")
        case get_location_from_postal_json(text) do
          nil ->
            ExGram.send_message(telegram_id, "Invalid postal code. Please try again.")
          %{"road_name" => road_name, "lat" => lat, "lon" => lon} ->
            ProfileFSM.update_user_location(telegram_id, {String.to_float(lat), String.to_float(lon)}, road_name)
            |> UserProfile.open_user_profile()
            StateManager.delete_state(telegram_id)
          err ->
            error_fallback(telegram_id, err)
        end
        ExGram.delete_message(telegram_id, message_id)

      %{state: "complete_profile_to_post"} ->
        case Users.update_pub_user(user, %{"username" => text}) do
          {:ok, _} ->
            post_orb(telegram_id)
          {:error, changeset} ->
            ExGram.send_message(telegram_id, "Username taken. Please choose another username.")
            err -> error_fallback(telegram_id, err)
        end

      %{state: "name" <> message_id, path: "self/update"} = user_state ->
        with {:ok, user} <- Users.update_user(user, %{public_profile: %{public_name: text}}) do
          StateManager.delete_state(telegram_id)
          UserProfile.open_user_profile(user)
        else
          err -> error_fallback(telegram_id, err)
        end

      %{state: "bio" <> message_id, path: "self/update"} ->
        with {:ok, user} <- Users.update_user(user, %{public_profile: %{bio: text}}) do
          StateManager.delete_state(telegram_id)
          UserProfile.open_user_profile(user)
        else
          err -> error_fallback(telegram_id, err)
        end

      %{state: "onboarding"} = user_state ->
        with changeset <- User.email_changeset(user, %{email: text}),
            :valid <- changeset.valid?,
            user <- Users.get_user_by_email(text) do
              Phos.Repo.update(changeset)
              Users.deliver_user_confirmation_instructions(user, &url(~p"/users/confirmtg/#{&1}"))
              ExGram.send_message(telegram_id, "An email has been sent to #{text} if it exists. Please check your inbox and follow the instructions to link your account.\n\nIf you have wrongly entered your email, restart the /register process.")
              StateManager.delete_state(telegram_id)
          else
            {:error, changeset} ->
              ExGram.send_message(telegram_id, "This is not a valid email, please try again or return to /start to cancel")
            nil ->
              ExGram.send_message(telegram_id, "You already have an account with us. Would you like to link your telegram to your Scratchbac account?", reply_markup: Button.build_link_account_button())
            err -> error_fallback(telegram_id, err)
          end

      %{state: "link_account"} ->
        case Regex.run(~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i, text) do
          [email, _domain] ->
            case Users.get_user_by_email(email) do
              nil ->
                ExGram.send_message(telegram_id, "No account found with that email. Please try again or return to /start")
              %{integrations: %{telegram_chat_id: _}} ->
                ExGram.send_message(telegram_id, "Your account is already linked to a telegram account. Unlink your account at web.scratchbac.com before linking to another telegram account.")
              user ->
                  Users.deliver_telegram_bind_confirmation_instructions(user, telegram_id, &url(~p"/users/bind/telegram/#{&1}"))
                  ExGram.send_message(telegram_id, "An email has been sent to #{email} if it exists. Please check your inbox and follow the instructions to link your account.")
                  StateManager.delete_state(telegram_id)
            end
          nil ->
            ExGram.send_message(telegram_id, "Your email is invalid, please try again or return to /start")
          err -> error_fallback(telegram_id, err)
        end

      %{state: "description", path: "orb/create"} = branch ->
        CreateOrb.set_description(branch, text)
        # CreateOrb.create_orb_path_transition(user, :description, text)
      %{state: "location", path: "orb/create"} = branch ->
        CreateOrb.set_location(branch, text)
      _ ->
        nil
    end
  end
end
