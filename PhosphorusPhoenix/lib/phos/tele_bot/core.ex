defmodule Phos.TeleBot.Core do
  use Phoenix.Component
  use PhosWeb, :html

  require Logger
  @bot :phos_telebot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  alias Phos.{Users}
  alias Phos.Users.User
  alias Phos.TeleBot.{StateManager, CreateOrb, ProfileFSM, OnboardingFSM}
  alias Phos.TeleBot.Core.{UserProfile}
  alias Phos.TeleBot.Components.{Button, Template}

  @guest_splash "https://imgur.com/a/Z2vphEX"
  @user_splash "https://imgur.com/a/GgdHYqy"
  @faq_splash "https://imgur.com/a/hkFJfOo"

  command("start", description: "Start using the Scratchbac bot")
  command("menu", description: "Show the main menu")
  command("help", description: "Show the help menu")
  command("post", description: "Post something")
  command("register", description: "Register an account")
  command("profile", description: "View your profile")
  command("myposts", description: "Show your previous posts")
  command("latestposts", description: "Show the posts around you")
  command("faq", description: "Show the Frequently Asked Questions")
  command("feedback", description: "Send us your feedback")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  def handle({:message, :start, %{"chat" => %{"id" => telegram_id}}}) do
    start_menu(telegram_id)
  end

  def handle({:message, :menu, %{"chat" => %{"id" => telegram_id}}}) do
    main_menu(telegram_id)
  end

  def handle({:message, :help, %{"chat" => %{"id" => telegram_id}}}) do
    ExGram.send_message(telegram_id, Template.help_text_builder(%{}))
  end

  @doc """
  Handle messages as requested by menus (Postal codes, email addresses, createorb inner_title etc.)
  """
  def handle({:message, :text, %{"chat" => %{"id" => telegram_id}, "text" => text}}) do
    with {:ok, user_state} <- StateManager.get_state(telegram_id),
         {:ok, user} <- get_user_by_telegram(telegram_id) do
        message_route(user_state, [user: user, telegram_id: telegram_id, text: text])
      else
        {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
        _ -> nil
      end
  end

  # @doc """
  # Check if meets all necessary profile fields to post or user has a post ongoing, prompt to continue editing or reset
  # """
  def handle({:message, :post, %{"chat" => %{"id" => telegram_id}}}) do
    post_orb(telegram_id)
  end

  def handle({:message, :register, %{"chat" => %{"id" => telegram_id}}}) do
    case get_user_by_telegram(telegram_id) do
      {:ok, %{tele_id: telegram_id, email: email}} when not is_nil(email) ->
        ExGram.send_message(telegram_id, "You have completed registration!")
      {:ok, _} ->
        onboarding_register_text(telegram_id)
      {:error, :user_not_found} ->
        error_fallback(telegram_id, "User not found")
    end
  end

  def handle({:message, :myposts, %{"chat" => %{"id" => telegram_id}}}) do
    open_myposts(telegram_id)
  end

  def handle({:message, :latestposts, %{"chat" => %{"id" => telegram_id}}}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id) do
      open_latest_posts(user)
    else
      {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
      err -> error_fallback(telegram_id, err)
    end
  end

  def handle({:message, :profile, %{"chat" => %{"id" => telegram_id}}}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id) do
      UserProfile.open_user_profile(user)
    else
      {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
      err -> error_fallback(telegram_id, err)
    end
  end

  def handle({:message, :faq, %{"chat" => %{"id" => telegram_id}}}) do
    faq(telegram_id, nil)
  end

  def handle({:message, :feedback, %{"chat" => %{"id" => telegram_id}}}) do
    feedback(telegram_id, nil)
  end

  def handle({:photo, %{"chat" => %{"id" => telegram_id}} = payload}) do
    with {:ok, user} <- get_user_by_telegram(telegram_id),
         {:ok, %{branch: branch}} <- StateManager.get_state(telegram_id),
         {:ok, %{message_id: message_id}} <- ExGram.send_message(telegram_id, "Setting photo...") do
      case branch do
        %{path: "self/update", state: "picture", } ->
          UserProfile.set_picture(user, payload)
        %{path: "orb/create", state: "media"} ->
          CreateOrb.set_picture(user, payload)
        %{path: "orb/create"} ->
          ExGram.send_message(telegram_id, "Please type a description for your post before uploading a media.")
        _ -> nil
      end
      ExGram.delete_message(telegram_id, message_id)
    else
      {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
      err -> error_fallback(telegram_id, err)
    end
  end

  def handle({:video, %{"chat" => %{"id" => telegram_id}}}) do
    with {:ok, _user} <- get_user_by_telegram(telegram_id),
         {:ok, %{branch: branch}} <- StateManager.get_state(telegram_id),
         {:ok, %{message_id: message_id}} <- ExGram.send_message(telegram_id, "Setting video...") do
      case branch do
        %{path: "orb/create", state: "media"} ->
          ExGram.send_message(telegram_id, "Sorry, we do not support video uploads yet. Please attach an image instead.")
        %{path: "orb/create"} ->
          ExGram.send_message(telegram_id, "Please type a description for your post before uploading a media.")
        _ -> nil
      end
      ExGram.delete_message(telegram_id, message_id)
    else
      {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
      err -> error_fallback(telegram_id, err)
    end
  end

  # ====================
  # CALLBACK QUERY
  # ====================

  def handle({:callback_query, %{"data" => "start_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}}}) do
    case type do
      "startmenu" <> message_id ->
        start_menu(telegram_id, message_id)
      "mainmenu" <> message_id ->
        main_menu(telegram_id, message_id)
      "faq" <> message_id ->
        faq(telegram_id, message_id)
      "feedback" <> message_id ->
        feedback(telegram_id, message_id)
    end
  end

  def handle({:callback_query, %{"data" => "onboarding_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}} = payload})
    when type in ["register", "linkaccount", "username"] do
    with {:ok, _user} <- get_user_by_telegram(telegram_id) do
      case type do
        "register" ->
          onboarding_register(telegram_id)
        "linkaccount" ->
          onboarding_linkaccount(telegram_id)
        "username" ->
          onboarding_username(telegram_id, payload)
        end
    end
  end

  def handle({:callback_query, %{"data" => "menu_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}}}) do
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

  def handle({:callback_query, %{"data" => "createorb_back_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}}})
      when type in ["description", "location", "media"] do
    with {:ok, _user} <- get_user_by_telegram(telegram_id),
         {:ok, %{branch: branch}} <- StateManager.get_state(telegram_id) do
      CreateOrb.transition(branch, type)
    else
      {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
      err -> error_fallback(telegram_id, err)
    end
  end

  def handle({:callback_query, %{"data" => "createorb_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}}})
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
          CreateOrb.transition(branch, "preview")
        {"post", %{path: "orb/create"}} ->
          CreateOrb.post(branch, user)
      end
    else
      {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
      err -> error_fallback(telegram_id, err)
    end
  end

  # @doc """
  #   Handle callback query for edit private_profile location to set the location based on the chosen type
  # """
  def handle({:callback_query, %{"data" => "edit_profile_locationtype_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}}}) when type in ["home", "work", "live"] do
    UserProfile.edit_locationtype_prompt(telegram_id, type)
  end

  # @doc """
  #   Handle callback query for edit profile name, bio, location type prompt, picture
  # """
  def handle({:callback_query, %{"data" => "edit_profile_" <> type, "message" => %{"chat" => %{"id" => telegram_id}}}}) do
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
  def handle({:inline_query, %{"id" => query_id, "query" => "myposts", "from" => %{"id" => telegram_id}}}) do
    open_myposts(telegram_id, query_id)
  end

  def handle({:inline_query, %{"id" => query_id, "query" => type, "from" => %{"id" => telegram_id}}}) when type in ["home", "work", "live"] do
    with {:ok, %{private_profile: private_profile} = user} when not is_nil(private_profile) <- get_user_by_telegram(telegram_id) do
      case Enum.find(private_profile.geolocation, fn loc -> loc.id == type end) do
        nil -> ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: type}),
          parse_mode: "HTML", reply_markup: Button.build_location_specific_button(type))
        %{geohash: geohash} ->
          ExGram.send_message(telegram_id, "Loading posts from #{type} area...")
          %{data: orbs} = Phos.Action.orbs_by_geohashes({[:h3.parent(geohash, 8)], user.id}, limit: 12)
          build_inlinequery_orbs(orbs, user)
          |> then(fn ans -> ExGram.answer_inline_query(to_string(query_id), ans) end)
      end
    else
      {:ok, _user} -> ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: type}),
        parse_mode: "HTML", reply_markup: Button.build_location_specific_button(type))
      {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
      err -> error_fallback(telegram_id, err)
    end
  end


  # ====================
  # LOCATION MESSAGE
  # ====================

  def handle({:location, %{"location" => %{"latitude" => lat, "longitude" => lon}, "chat" => %{"id" => telegram_id}}}) do
    with {:ok, %{branch: branch }} <- StateManager.get_state(telegram_id) do
      case branch do
        %{path: "self/update"} ->
          with {:ok, _user} <- ProfileFSM.update_user_location(telegram_id, {lat, lon}, Phos.Mainland.World.locate(:h3.from_geo({lat, lon}, 11))) do
            case branch do
              %{data: %{return_to: "orb/create"}} ->
                post_orb(telegram_id)
              _ ->
                {:ok, user} = get_user_by_telegram(telegram_id)
                UserProfile.open_user_profile(user)
            end
          else
            err -> error_fallback(telegram_id, "Error updating self/update :location #{err}")
          end
        %{path: "orb/create", state: "location"} ->
          CreateOrb.set_location(branch, "live", [latlon: {lat, lon}])
        %{path: "orb/create"} ->
          ExGram.send_message(telegram_id, "Please type a description for your post before setting your location.")
        _ -> nil
      end
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  # Catch any other messages and do nothing
  def handle({_, _}), do: []
  def handle({_, _, _}), do: []

  def get_user_by_telegram(telegram_id), do: Users.get_user_by_telegram(telegram_id |> to_string())

  defp build_inlinequery_orbs(orbs, user) do
    if Enum.empty?(orbs) do
      [%ExGram.Model.InlineQueryResultArticle{
        id: "no_orbs",
        type: "article",
        title: "No posts found",
        description: "No posts found",
        input_message_content: %ExGram.Model.InputTextMessageContent{ %ExGram.Model.InputTextMessageContent{} |
          message_text: "No posts found", parse_mode: "HTML" },
        thumbnail_url: @user_splash
      }]
    else
      Enum.map(orbs, fn (%{payload: payload} = orb) when not is_nil(payload) ->
        media =
          Phos.Orbject.S3.get_all!("ORB", orb.id, "public/banner")
          |> (fn
            nil ->
              []
            media ->
              for {path, url} <- media do
                %Phos.Orbject.Structure.Media{
                  ext: MIME.from_path(path),
                  path: "public/banner" <> path,
                  url: url,
                  resolution:
                    path
                    |> String.split(".")
                    |> hd()
                    |> String.split("/")
                    |> List.last()
                }
              end
          end).()
          |> Enum.filter(fn m -> m.resolution == "lossless" end)
          |> List.wrap()

        media =
          if not Enum.empty?(media) and not String.contains?(hd(media).url, "localhost") do
            hd(media).url
          else
            @user_splash
          end

        %ExGram.Model.InlineQueryResultArticle{
          id: orb.id,
          type: "article",
          title: orb.title,
          description: orb.payload.inner_title,
          input_message_content: %ExGram.Model.InputTextMessageContent{ %ExGram.Model.InputTextMessageContent{} |
            message_text: Template.orb_telegram_orb_builder(orb), parse_mode: "HTML" },
          thumbnail_url: media,
          reply_markup: Button.build_orb_notification_button(orb, user)
        }
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
    end
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
        error_fallback(id, msg)
    end
  end

  def onboarding_register(telegram_id) do
    {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id, Template.onboarding_register_text_builder(%{}), parse_mode: "HTML")
    {:ok, user_state} = StateManager.new_state(telegram_id)
    user_state
    |> Map.put(:branch, %OnboardingFSM{telegram_id: telegram_id, state: "register",
      metadata: %{message_id: message_id}})
    |> StateManager.update_state(telegram_id)
  end

  def onboarding_linkaccount(telegram_id) do
    with {:ok, %{branch: %{data: %{email: email}}}} <- StateManager.get_state(telegram_id),
         %User{} = user <- Users.get_user_by_email(email) do
      Users.deliver_telegram_bind_confirmation_instructions(user, telegram_id, &url(~p"/users/bind/telegram/#{&1}"))
      ExGram.send_message(telegram_id, "An email has been sent to #{email} if it exists. Please check your inbox and follow the instructions to link your account.")
      StateManager.delete_state(telegram_id)
    else
      err -> error_fallback(telegram_id, err)
    end
  end

  def onboarding_username(telegram_id, payload) do
    {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id, Template.edit_profile_username_text_builder(%{}),
        parse_mode: "HTML", reply_markup: Button.build_choose_username_keyboard(payload |> get_in(["message", "chat", "username"])))
    {:ok, user_state} = StateManager.new_state(telegram_id)
    user_state
    |> Map.put(:branch, %OnboardingFSM{telegram_id: telegram_id, state: "username",
      metadata: %{message_id: message_id}})
    |> StateManager.update_state(telegram_id)
  end

  defp start_menu(telegram_id), do: start_menu(telegram_id, nil)
  defp start_menu(telegram_id, message_id) do
    StateManager.delete_state(telegram_id)
    start_main_menu_check_and_register(telegram_id)
    with {:ok, %{email: email}} when not is_nil(email) <- get_user_by_telegram(telegram_id) do
      start_menu_text(telegram_id, message_id)
    else
      _ ->
        onboard_text(telegram_id)
    end
  end

  defp start_menu_text(telegram_id, nil) do
    {:ok, %{message_id: message_id}} = ExGram.send_photo(telegram_id, @guest_splash,
      caption: Template.start_menu_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id,
      reply_markup: Button.build_start_inlinekeyboard(message_id))
  end
  defp start_menu_text(telegram_id, message_id) do
    ExGram.edit_message_media(%ExGram.Model.InputMediaPhoto{media:
      @guest_splash, type: "photo",
      caption: Template.start_menu_text_builder(%{}), parse_mode: "HTML"},
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), reply_markup: Button.build_start_inlinekeyboard(message_id))
  end

  defp main_menu(telegram_id), do: main_menu(telegram_id, nil)
  defp main_menu(telegram_id, ""), do: main_menu(telegram_id, nil)
  defp main_menu(telegram_id, message_id) do
    StateManager.delete_state(telegram_id)
    start_main_menu_check_and_register(telegram_id)
    main_menu_text(telegram_id, message_id)
  end

  defp main_menu_text(telegram_id, nil) do
    {:ok, %{message_id: message_id}} = ExGram.send_photo(telegram_id, @user_splash,
      caption: Template.main_menu_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id, reply_markup: Button.build_menu_inlinekeyboard(message_id))
  end
  defp main_menu_text(telegram_id, message_id) do
    {:ok, %{message_id: _message_id}} = ExGram.edit_message_media(%ExGram.Model.InputMediaPhoto{media:
      @user_splash, type: "photo", caption: Template.main_menu_text_builder(%{}), parse_mode: "HTML"},
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), reply_markup: Button.build_menu_inlinekeyboard(message_id))
  end

  defp faq(telegram_id, ""), do: faq(telegram_id, nil)
  defp faq(telegram_id, nil) do
    {:ok, %{message_id: message_id}} = ExGram.send_photo(telegram_id, @faq_splash,
      caption: Template.faq_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id,
      reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end
  defp faq(telegram_id, message_id) do
    {:ok, %{message_id: _message_id}} = ExGram.edit_message_media(%ExGram.Model.InputMediaPhoto{media:
      @faq_splash, type: "photo", caption: Template.faq_text_builder(%{}), parse_mode: "HTML"},
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), reply_markup: Button.build_start_menu_inlinekeyboard(message_id))
  end

  defp feedback(telegram_id, ""), do: feedback(telegram_id, nil)
  defp feedback(telegram_id, nil) do
    {:ok, %{message_id: message_id}} = ExGram.send_photo(telegram_id, @faq_splash,
      caption: Template.feedback_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id,
      reply_markup: Button.build_main_menu_inlinekeyboard(message_id))
  end
  defp feedback(telegram_id, message_id) do
    ExGram.edit_message_media(%ExGram.Model.InputMediaPhoto{media:
      @faq_splash, type: "photo", caption: Template.feedback_text_builder(%{}), parse_mode: "HTML"},
      chat_id: telegram_id, message_id: message_id |> String.to_integer(), reply_markup: Button.build_start_menu_inlinekeyboard(message_id))
  end

  defp onboard_text(telegram_id) do
    {:ok, _user} = get_user_by_telegram(telegram_id)
    {:ok, %{message_id: message_id}} = ExGram.send_photo(telegram_id, @guest_splash,
      caption: Template.onboarding_text_builder(%{}), parse_mode: "HTML")
    ExGram.edit_message_reply_markup(chat_id: telegram_id, message_id: message_id,
      reply_markup: Button.build_start_inlinekeyboard(message_id))
  end

  defp start_main_menu_check_and_register(telegram_id) do
    with {:user_exist, true} <- {:user_exist, Users.telegram_user_exists?(telegram_id)},
         {:integrations_exist, {:ok, %{integrations: %{telegram_chat_id: telegram_chat_id}}}}
          when not is_nil(telegram_chat_id) <- {:integrations_exist, get_user_by_telegram(telegram_id)} do
      :ok
    else
      {:user_exist, false} ->
        create_user(%{"id" => telegram_id})
        :ok
      {:integrations_exist, {:ok, %{tele_id: _tele_id} = user}} ->
        params = %{integrations: %{telegram_chat_id: telegram_id |> to_string()}}
        User.telegram_changeset(user, params)
        |> Phos.Repo.update()
    end
  end

  defp onboarding_register_text(telegram_id) do
    ExGram.send_message(telegram_id, Template.not_yet_registered_text_builder(%{}), parse_mode: "HTML",
      reply_markup: Button.build_onboarding_register_button())
  end

  def error_fallback(telegram_id, err) do
    error_fallback(telegram_id)
    IO.inspect err
  end
  def error_fallback(telegram_id) do
    StateManager.delete_state(telegram_id)
    ExGram.send_message(telegram_id, Template.fallback_text_builder(%{}), parse_mode: "HTML")
    main_menu(telegram_id)
  end

  def dispatch_messages(events) do
    Enum.map(events, fn %{chat_id: chat_id, orb: orb} ->
      with {:ok, user} <- get_user_by_telegram(chat_id) do
        case orb.media do
          true ->
            if String.contains?(PhosWeb.Endpoint.url, "localhost") do
              # For development
              ExGram.send_photo(chat_id, @user_splash,
                caption: Template.orb_telegram_orb_builder(orb), parse_mode: "HTML",
                reply_markup: Button.build_orb_notification_button(orb, user))
            else
              # For production
              media =
                Phos.Orbject.S3.get_all!("ORB", orb.id, "public/banner")
                |> (fn
                  nil ->
                    []
                  media ->
                    for {path, url} <- media do
                      %Phos.Orbject.Structure.Media{
                        ext: MIME.from_path(path) |> String.split("/") |> hd,
                        path: "public/banner" <> path,
                        url: url,
                        resolution:
                          path
                          |> String.split(".")
                          |> hd()
                          |> String.split("/")
                          |> List.last()
                      }
                    end
                end).()
                |> Enum.filter(fn m -> m.resolution == "lossless" end)
                |> List.wrap()

              case media do
                [%Phos.Orbject.Structure.Media{ext: ext} | _] when ext in ["video"] ->
                  ExGram.send_message(chat_id, Template.orb_telegram_orb_builder(orb), parse_mode: "HTML",
                    reply_markup: Button.build_orb_notification_button(orb, user))
                  # ExGram.send_video(chat_id, hd(media).url,
                  #   caption: Template.orb_telegram_orb_builder(orb), parse_mode: "HTML",
                  #   reply_markup: Button.build_orb_notification_button(orb, user))
                [%Phos.Orbject.Structure.Media{ext: ext} | _] when ext in ["application", "image"] ->
                  ExGram.send_photo(chat_id, hd(media).url,
                    caption: Template.orb_telegram_orb_builder(orb), parse_mode: "HTML",
                    reply_markup: Button.build_orb_notification_button(orb, user))
                _ -> :ok
              end
            end
          _ ->
            ExGram.send_message(chat_id, Template.orb_telegram_orb_builder(orb), parse_mode: "HTML",
              reply_markup: Button.build_orb_notification_button(orb, user))
        end
      else
        {:error, :user_not_found} -> :ok
      end
    end)
  end

  defp open_latest_posts(user), do: open_latest_posts(user, nil)
  defp open_latest_posts(user, ""), do: open_latest_posts(user, nil)
  defp open_latest_posts(%{tele_id: telegram_id} = user, nil) do
    ExGram.send_message(telegram_id, Template.latest_posts_text_builder(user),
      parse_mode: "HTML", reply_markup: Button.build_latest_posts_inline_button())
  end
  defp open_latest_posts(%{tele_id: telegram_id} = user, message_id) do
    ExGram.edit_message_text(Template.latest_posts_text_builder(user), chat_id: telegram_id,
      message_id: message_id |> String.to_integer(), parse_mode: "HTML",
      reply_markup: Button.build_latest_posts_inline_button(message_id |> String.to_integer()))
  end

  def open_myposts(telegram_id) do
    ExGram.send_message(telegram_id, "<u>Click on the 📕 My Posts button to view your posts.</u>",
      parse_mode: "HTML", reply_markup: Button.build_myposts_inlinekeyboard())
  end
  def open_myposts(telegram_id, query_id) do
    with {:ok, user} <- get_user_by_telegram(telegram_id) do
      case user do
        %User{email: _email, media: true, username: _username} ->
          ExGram.send_message(telegram_id, "Loading your posts...")
          %{data: orbs} = Phos.Action.orbs_by_initiators([user.id], 1)
          build_inlinequery_orbs(orbs, user)
          |> then(fn ans -> ExGram.answer_inline_query(to_string(query_id), ans) end)
        %User{email: nil} ->
          ExGram.send_message(telegram_id, "You have not posted anything since you are not registered or confirmed your account!
            \n<u>Click on the \"Register\" button</u>", parse_mode: "HTML", reply_markup: Button.build_onboarding_register_button())
      end
    else
      {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
      err -> error_fallback(telegram_id, err)
    end
  end


  def post_orb(telegram_id) do
    with {:ok, user} <- get_user_by_telegram(telegram_id) do
      case user do
        %User{email: nil} ->
          onboarding_register_text(telegram_id)
        %User{username: nil} ->
          ExGram.send_message(telegram_id, Template.incomplete_profile_text_builder(%{}),
            parse_mode: "HTML", reply_markup: Button.build_onboarding_username_button())
        %User{media: false} ->
          {:ok, user_state} = StateManager.new_state(telegram_id)
          user_state
          |> Map.put(:branch, %ProfileFSM{telegram_id: telegram_id, data: %{return_to: "orb/create"}, state: "picture"})
          |> StateManager.update_state(telegram_id)
          ExGram.send_message(telegram_id, "Almost there! You need to set your user profile picture first.\n\n<i>(Use the 📎 button to attach image)</i>",
            parse_mode: "HTML")
        %User{email: _email, media: true, username: _username} ->
          CreateOrb.create_fresh_orb_form(telegram_id)
        err -> error_fallback(telegram_id, err)
      end
    else
      {:error, :user_not_found} -> error_fallback(telegram_id, "User not found")
    end
  end

  def message_route(%{branch: branch} = user_state, opts) do
    user = opts[:user]
    telegram_id = opts[:telegram_id]
    text = opts[:text]
    case branch do
      %{path: "self/update", state: "location"} ->
        {:ok, %{message_id: message_id}} = ExGram.send_message(telegram_id, "Checking location...")
        case Phos.Mainland.Postal.locate(text) do
          nil ->
            ExGram.send_message(telegram_id, "Invalid postal code. Please try again.")
          %{"road_name" => road_name, "lat" => lat, "lon" => lon} ->
            with {:ok, _user} <- ProfileFSM.update_user_location(telegram_id, {String.to_float(lat), String.to_float(lon)}, road_name) do
              StateManager.delete_state(telegram_id)
              case branch do
                %{data: %{return_to: "orb/create"}} ->
                  post_orb(telegram_id)
                _ ->
                  {:ok, user} = get_user_by_telegram(telegram_id)
                  UserProfile.open_user_profile(user)
              end
            else
              err -> error_fallback(telegram_id, "Error updating self/update :location #{err}")
            end
          err ->
            error_fallback(telegram_id, err)
        end
        ExGram.delete_message(telegram_id, message_id)

      %{path: "self/update", state: "livelocation"} ->
        ExGram.send_message(telegram_id, "You must share your current/live location to update your location.\n\n<i>(Use the 📎 button to attach image)</i>", parse_mode: "HTML")

      %{path: "self/update", state: "name" <> _message_id} ->
        with {:ok, user} <- Users.update_user(user, %{public_profile: %{public_name: text}}) do
          StateManager.delete_state(telegram_id)
          UserProfile.open_user_profile(user)
        else
          err -> error_fallback(telegram_id, err)
        end

      %{path: "self/update", state: "bio" <> _message_id} ->
        with {:ok, user} <- Users.update_user(user, %{public_profile: %{bio: text}}) do
          StateManager.delete_state(telegram_id)
          UserProfile.open_user_profile(user)
        else
          err -> error_fallback(telegram_id, err)
        end

      %{path: "self/onboarding", state: "register"} ->
        with {:email_changeset, changeset} <- {:email_changeset, User.email_changeset(user, %{email: text})},
             {:valid, %{valid?: true} = changeset} <- {:valid, changeset},
             {:ok, %{branch: _branch}} <- StateManager.get_state(telegram_id) do
                {:ok, user} = Phos.Repo.update(changeset)
                Users.deliver_user_confirmation_instructions(user, &url(~p"/users/confirmtg/#{&1}"))
                ExGram.send_message(telegram_id, "An email has been sent to #{text} if it exists. Please check your inbox and follow the instructions to link your account.\n\nIf you have wrongly entered your email, restart the /register process.")
                StateManager.delete_state(telegram_id)
          else
            {:valid, %{valid?: false, errors: [email: {"has already been taken", _}]}} ->
              ExGram.send_message(telegram_id, "This email is in use. Would you like to link your telegram to your Scratchbac account?\n\n<u>Click on the Link Account button</u>", parse_mode: "HTML", reply_markup: Button.build_link_account_button())
              {_prev, branch} = get_and_update_in(branch.data.email, &{&1, text})
              Map.put(user_state, :branch, branch)
              |> StateManager.update_state(telegram_id)
            {:valid, %{valid?: false}} ->
              ExGram.send_message(telegram_id, "This email is not valid. Please try again or return to /start to cancel")
            err -> error_fallback(telegram_id, err)
          end

      %{path: "self/onboarding", state: "username"} ->
        text = String.downcase(text)
        case Users.update_pub_user(user, %{"username" => text}) do
          {:ok, _} ->
            post_orb(telegram_id)
          {:error, %{valid?: false, errors: [username: {"has already been taken", _}]}} ->
            ExGram.send_message(telegram_id, "Username taken. Please choose another username.")
          {:error, %{valid?: false}} ->
            ExGram.send_message(telegram_id, "Username does not meet requirements.\n\n- <u>5 characters long</u>\n - <u>letters and numbers</u>\n\nPlease try again.", parse_mode: "HTML")
        end

      %{path: "orb/create", state: "description"} = branch ->
        CreateOrb.set_description(branch, text)
      _ ->
        nil
    end
  end
end
