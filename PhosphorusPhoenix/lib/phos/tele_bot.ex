defmodule Phos.TeleBot do
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
  alias __MODULE__.{Config, StateManager, CreateOrbPath, UserProfile}
  alias Phos.TeleBot.Components.{Button, Template}

  command("start", description: "Start using the Scratchbac bot")
  command("menu", description: "Show the main menu")
  command("help", description: "Show the help menu")
  command("post", description: "Post something")
  command("register", description: "Register an account")
  command("profile", description: "View your profile")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  # ====================
  # GENERIC MESSAGES
  # ====================

  def handle({:message, :start, payload}) do
    telegram_id = payload |> get_in(["from", "id"])
    StateManager.delete_state(telegram_id)
    start_menu(telegram_id)
  end

  def handle({:message, :menu, payload}) do
    telegram_id = payload |> get_in(["from", "id"])
    StateManager.delete_state(telegram_id)
    main_menu(telegram_id)
  end

  def handle({:message, :help, payload}) do
    ExGram.send_message(payload |> get_in(["chat", "id"]), Template.help_text_builder(%{}))
  end

  @doc """
  Handle messages as requested by menus (Postal codes, email addresses, createorb inner_title etc.)
  """
  def handle({:message, :text, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    {:ok, user} = get_user_by_telegram(telegram_id)

    case StateManager.get_state(telegram_id) do
      %{state: "set_location"} ->
        text = payload |> get_in(["text"])
        case get_location_from_postal_json(text) do
          nil ->
            ExGram.send_message(telegram_id, "Invalid postal code. Please try again.")
          _ ->
            %{"road_name" => road_name, "lat" => lat, "lon" => lon} = get_location_from_postal_json(text)
            update_user_location(telegram_id, {String.to_float(lat), String.to_float(lon)}, road_name)
            StateManager.delete_state(telegram_id)
        end

      %{state: "complete_profile_to_post"} ->
        text = payload |> get_in(["text"])
        user_state = StateManager.get_state(telegram_id)
        case Users.update_pub_user(user, %{"username" => text}) do
          {:ok, _} ->
            post_orb(telegram_id)
          {:error, changeset} ->
            ExGram.send_message(telegram_id, "Username taken. Please choose another username.")
        end

      %{state: "edit_profile_" <> type} ->
        text = payload |> get_in(["text"])
        case type do
          "name" <> message_id ->
            {:ok, user} = Users.update_user(user, %{public_profile: %{public_name: text}})
            UserProfile.open_user_profile(user)
          "bio" <> message_id ->
            {:ok, user} = Users.update_user(user, %{public_profile: %{bio: text}})
            UserProfile.open_user_profile(user)
        end

      %{state: "onboarding"} = user_state ->
        text = payload |> get_in(["text"])
        is_valid_email = not is_nil(Regex.run(~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i, text))
        user_by_email = Users.get_user_by_email(text)
        case {is_valid_email, user_by_email} do
          {true, nil} ->
            {:ok, user} = User.email_changeset(user, %{email: text}) |> Phos.Repo.update()
            Users.deliver_user_confirmation_instructions(user, &url(~p"/users/confirmtg/#{&1}"))
            ExGram.send_message(telegram_id, "An email has been sent to #{text} if it exists. Please check your inbox and follow the instructions to link your account.\n\nIf you have wrongly entered your email, restart the /register process.")
            StateManager.delete_state(telegram_id)
          {true, user} ->
            ExGram.send_message(telegram_id, "You already have an account with us. Would you like to link your telegram to your Scratchbac account?", reply_markup: Button.build_link_account_button())
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
              %{integrations: %{telegram_chat_id: _}} ->
                ExGram.send_message(telegram_id, "Your account is already linked to a telegram account. Unlink your account at web.scratchbac.com before linking to another telegram account.")
              user ->
                  Users.deliver_telegram_bind_confirmation_instructions(user, telegram_id, &url(~p"/users/bind/telegram/#{&1}"))
                  ExGram.send_message(telegram_id, "An email has been sent to #{email} if it exists. Please check your inbox and follow the instructions to link your account.")
                  StateManager.delete_state(telegram_id)
            end
          nil ->
            ExGram.send_message(telegram_id, "Your email is invalid, please try again or return to /start")
        end

      %{state: "createorb_" <> type} when type in ["description"] ->
        text = payload |> get_in(["text"])
        CreateOrbPath.create_orb_path_transition(user, String.to_atom(type), text)
      _ ->
        nil
    end
  end

  # @doc """
  # Check if meets all necessary profile fields to post or user has a post ongoing, prompt to continue editing or reset
  # """
  def handle({:message, :post, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    post_orb(telegram_id)
  end

  def handle({:message, :register, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    with {:user_exist, user_exist} <- {:user_exist, Users.telegram_user_exists?(telegram_id)},
         {:user_confirmed, {:ok, %{confirmed_at: date}} = user } when not is_nil(date) <- {:user_confirmed, get_user_by_telegram(telegram_id)},
         {:user, {:ok, %{integrations: %{telegram_chat_id: _}} = user}}  <- {:user, get_user_by_telegram(telegram_id)} do
          ExGram.send_message(telegram_id, "You have completed registration!")
        else
          {:user, {:ok, %{integrations: _} = user}} ->
            ExGram.send_message(telegram_id, "You already have an account with us. Would you like to link your telegram to your Scratchbac account?",
              reply_markup: Button.build_link_account_button())
          _ ->
            onboarding_register_text(telegram_id)
    end
  end

  def handle({:message, :profile, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    {:ok, user} = get_user_by_telegram(telegram_id)
    UserProfile.open_user_profile(user)
  end

  def handle({:photo, payload}) do
    telegram_id = payload |> get_in(["chat", "id"])
    {:ok, user} = get_user_by_telegram(telegram_id)
    case StateManager.get_state(telegram_id) do
      %{state: "set_profile_picture"} ->
        set_user_profile_picture(user, payload)
      %{state: "createorb" <> _type} = user_state ->
        CreateOrbPath.create_orb_path_transition(user, :media, payload)
      _ -> nil
    end
  end

  # ====================
  # CALLBACK QUERY
  # ====================

  def handle({:callback_query, %{"data" => "start_" <> type} = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    case type do
      "mainmenu" <> message_id ->
        main_menu(telegram_id, message_id)
      "faq" <> message_id ->
        faq(telegram_id, message_id)
      "feedback" <> message_id ->
        feedback(telegram_id, message_id)
    end
  end

  def handle({:callback_query, %{"data" => "onboarding"} = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    user_state = StateManager.get_state(telegram_id)
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "onboarding", data: %{}}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.send_message(telegram_id, "What is your email?\n\nPlease provide us with a valid email, you will receive a confirmation email to confirm your registration.", parse_mode: "HTML")
  end

  def handle({:callback_query, %{"data" => "menu_" <> type} = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    {:ok, user} = get_user_by_telegram(telegram_id)
    case type do
      "post" ->
        post_orb(telegram_id)
      "openprofile" <> message_id ->
        UserProfile.open_user_profile(user, message_id)
      "latestposts" <> message_id ->
        open_latest_posts(user, message_id)
    end
  end

  def handle({:callback_query, %{"data" => "createorb_back_" <> type } = payload}) when type in ["description", "location", "media"] do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    {:ok, user} = get_user_by_telegram(telegram_id)
    CreateOrbPath.create_orb_path(user, String.to_atom(type))
  end

  def handle({:callback_query, %{"data" => "createorb_" <> type } = payload}) when type in ["location_home", "location_work",
     "location_live", "description", "location", "media", "preview", "post"] do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    {:ok, user} = get_user_by_telegram(telegram_id)
    case type do
      "location_home" ->
        CreateOrbPath.create_orb_path_transition(user, :location, "home")
      "location_work" ->
        CreateOrbPath.create_orb_path_transition(user, :location, "work")
      "location_live" ->
        CreateOrbPath.create_orb_path_transition(user, :location, "live")
      "preview" ->
        CreateOrbPath.create_orb_path_transition(user, :preview)
      "post" ->
        CreateOrbPath.create_orb_path(user, :post)
    end
  end

  # PROFILE - LINK ACCOUNT
  def handle({:callback_query, %{"data" => "link_account" } = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    {:ok, user} = get_user_by_telegram(telegram_id)

    case user do
      %{integrations: %{telegram_chat_id: _}} ->
        ExGram.send_message(telegram_id, "You have already linked your telegram account to the Scratchbac App.")
      _ ->
        profilefsm = %Phos.TeleBot.ProfileFSM{state: "link_account"}
        StateManager.set_state(telegram_id, profilefsm)
        ExGram.send_message(telegram_id, "To link your telegram to the Scratchbac App, please type the same email address you used to register on the Scratchbac App.", reply_markup: Button.build_cancel_button())
    end
  end

  # @doc """
  #  Handle callback query for user to complete their profile so they can start posting
  # """
  def handle({:callback_query, %{"data" => "complete_profile_for_post"} = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    {:ok, user} = get_user_by_telegram(telegram_id)
    user_state = StateManager.get_state(telegram_id)

    # Check if user already set his username
    profilefsm = %Phos.TeleBot.ProfileFSM{state: "complete_profile_to_post"}
    StateManager.set_state(telegram_id, profilefsm)
    ExGram.send_message(telegram_id, Template.edit_profile_username_text_builder(%{}),
      parse_mode: "HTML", reply_markup: Button.build_choose_username_keyboard(payload |> get_in(["message", "chat", "username"])))
  end

  # @doc """
  #   Handle callback query for edit private_profile location to set the location based on the chosen type
  # """
  def handle({:callback_query, %{"data" => "edit_profile_locationtype_" <> type } = payload}) when type in ["home", "work", "live"] do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    text = "Please type your postal code or send your location for #{type} location."

    locationfsm = %Phos.TeleBot.LocationFSM{state: "set_location", data: %{location_type: type}}
    StateManager.set_state(telegram_id, locationfsm)
    ExGram.send_message(telegram_id, text, reply_markup: Button.build_current_location_button())
  end

  # @doc """
  #   Handle callback query for edit profile name, bio, location type prompt, picture
  # """
  def handle({:callback_query, %{"data" => "edit_profile_" <> type} = payload}) do
    telegram_id = payload |> get_in(["message", "chat", "id"])
    case type do
      "name" <> message_id ->
        UserProfile.edit_user_profile_name(telegram_id, message_id)
      "bio" <> message_id ->
        UserProfile.edit_user_profile_bio(telegram_id, message_id)
      "location" <> message_id ->
        UserProfile.edit_user_profile_location(telegram_id, message_id)
      "picture" <> message_id ->
        UserProfile.edit_user_profile_picture(telegram_id, message_id)
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
  def handle({:inline_query, %{"query" => "myposts"} = payload}) do
    telegram_id = payload |> get_in(["from", "id"])
    StateManager.delete_state(telegram_id)
    query_id = payload |> get_in(["id"])
    {:ok, user} = get_user_by_telegram(telegram_id)
    %{data: orbs} = Phos.Action.orbs_by_initiators([user.id], 1)
    build_inlinequery_orbs(orbs)
    |> then(fn ans -> ExGram.answer_inline_query(to_string(query_id), ans) end)
  end

  def handle({:inline_query, %{"query" => type} = payload}) when type in ["home", "work", "live"] do
    telegram_id = payload |> get_in(["from", "id"])
    query_id = payload |> get_in(["id"])
    {:ok, user} = get_user_by_telegram(telegram_id)

    if user.private_profile do
      case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == type end) do
        nil -> ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: type}),
          parse_mode: "HTML", reply_markup: Button.build_location_specific_button(type))
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
        "createorb_current_location" ->
          {:ok, user} = get_user_by_telegram(telegram_id)
          {_prev, user_state} = get_and_update_in(user_state.data.geolocation.central_geohash, &{&1, :h3.from_geo({lat, lon}, 10)} )
          {_prev, user_state} = get_and_update_in(user_state.data.location_type, &{&1, :live} )
          StateManager.set_state(telegram_id, user_state)
          CreateOrbPath.create_orb_path_transition(user, :current_location)
          # ExGram.send_message(telegram_id, Template.orb_creation_preview_builder(user_state.data),
          #   parse_mode: "HTML", reply_markup: Button.build_orb_create_keyboard_button())
        _ ->
          ExGram.send_message(telegram_id, "Your location not set.")
      end
    end
  end

  # Catch any other messages and do nothing
  def handle({_, _}), do: []
  def handle({_, _, _}), do: []

  def get_user_by_telegram(telegram_id), do: Users.get_user_by_telegram(telegram_id |> to_string())

  defp create_fresh_orb_form(telegram_id) do
    {:ok, user} = get_user_by_telegram(telegram_id)
    user_state = %Phos.TeleBot.CreateOrbFSM{telegram_id: telegram_id, state: "home", data: %{}}
    {:ok, user_state} = Fsmx.transition(user_state, "createorb_description")
    StateManager.set_state(telegram_id, user_state)
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

  defp start_menu_text(telegram_id, message_id) do
    {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id,
      Template.start_menu_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id,
      reply_markup: Button.build_start_inlinekeyboard(message_id))
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
        IO.inspect "Creating user"
        user = create_user(%{"id" => telegram_id})
        telegram_id

      {:user, {:ok, user}} ->
        IO.inspect "Onboarding user"
        telegram_id
    end
  end

  defp onboarding_register_text(telegram_id) do
    ExGram.send_message(telegram_id, Template.not_yet_registered_text_builder(%{}), parse_mode: "HTML",
    reply_markup: Button.build_onboarding_register_button())
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
    {:ok, %{private_profile: priv} = user} = get_user_by_telegram(telegram_id)
    geos = case priv do
      nil ->
        []
      _ ->
        Map.get(priv, :geolocation, []) |> Enum.map(&Map.from_struct(&1) |> Enum.reduce(%{}, fn {k, v}, acc ->
          Map.put(acc, to_string(k), v) end)) |> Enum.reduce([], fn loc, acc ->
            case Map.get(loc, "id") == type do
              true -> acc
              _ -> [loc | acc]
            end
          end)
    end
    case Phos.Users.update_territorial_user(user, %{private_profile: %{user_id: user.id,
      geolocation: [%{"id" => type, "geohash" => :h3.from_geo(geo, 11), "location_description" => desc} | geos]}}) do
      {:ok, user} ->
        UserProfile.open_user_profile(user, nil)
        StateManager.delete_state(telegram_id)
      _ -> ExGram.send_message(telegram_id, "Your #{type} location is not set.", reply_markup: Button.build_menu_inlinekeyboard())
    end
  end

  def dispatch_messages(events) do
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

  defp get_location_from_postal_json(postal) do
    with {:ok, body} <- File.read("../HeimdallrNode/resources/postal_road_13_07_2023.json"),
         {:ok, json} <- Poison.decode(body) do
            if json[postal] do
              json[postal]
            else
              nil
            end
    end
  end

  defp set_user_profile_picture(user, payload) do
    media = [%{
      access: "public",
      essence: "profile",
      resolution: "lossy"
    }]
    with {:ok, media} <- Orbject.Structure.apply_media_changeset(%{id: user.id, archetype: "USR", media: media}),
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

      user_state = StateManager.get_state(user.integrations.telegram_chat_id)
      case user_state do
        %{data: %{return_to: "post"}} ->
          post_orb(user.integrations.telegram_chat_id)
        _ ->
          ExGram.send_message(user.integrations.telegram_chat_id, "Your profile picture has been updated", reply_markup: Button.build_menu_inlinekeyboard())
      end

     else
      err ->
        IO.inspect("Something went wrong: set_user_profile_picture #{err}")
    end
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
        profilefsm = %Phos.TeleBot.ProfileFSM{state: "set_profile_picture", data: %{return_to: "post"}}
        StateManager.set_state(telegram_id, profilefsm)
        ExGram.send_message(telegram_id, "Almost there! You need to set your user profile picture first.\n\n<i>(Use the 📎 button to attach image)</i>",
          parse_mode: "HTML")
      _ ->
        create_fresh_orb_form(telegram_id)
    end
  end
end
