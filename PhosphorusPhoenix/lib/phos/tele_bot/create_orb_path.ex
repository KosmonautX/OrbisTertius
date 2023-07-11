defmodule Phos.TeleBot.CreateOrbPath do
  alias Phos.TeleBot.{StateManager}
  alias Phos.TeleBot.Components.{Button, Template}

  alias Phos.TelegramNotification, as: TN

  def create_orb_path_transition(%{integrations: %{telegram_chat_id: telegram_id}} = user, :description, text) do
    user_state = StateManager.get_state(telegram_id)
    {_prev, user_state} = get_and_update_in(user_state.data.inner_title, &{&1, text})

    case Fsmx.transition(user_state, "createorb_location") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "You must type something for your post.")
    end
  end

  def create_orb_path(%{integrations: %{telegram_chat_id: telegram_id}} = user, :description) do
    user_state = StateManager.get_state(telegram_id)
    case Fsmx.transition(user_state, "createorb_description") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "Something went wrong.")
        IO.inspect(err)
    end
  end

  def create_orb_path(%{integrations: %{telegram_chat_id: telegram_id}} = user, :location) do
    user_state = StateManager.get_state(telegram_id)
    case Fsmx.transition(user_state, "createorb_location") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "Something went wrong.")
        IO.inspect(err)
    end
  end

  def create_orb_path_transition(%{integrations: %{telegram_chat_id: telegram_id}} = user, :location, type) do
    user_state = StateManager.get_state(telegram_id)

    case type do
      "home" ->
        if is_nil(user.private_profile) do
          ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: "home"}),
            parse_mode: "HTML", reply_markup: Button.build_location_specific_button("Home"))
        else
          geohash =
            case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == "home" end) do
              nil -> nil
              %{geohash: geohash} -> geohash
            end
          if is_nil(geohash) do
            ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: "home"}),
              parse_mode: "HTML", reply_markup: Button.build_location_specific_button("Home"))
          else
            {_prev, user_state} = get_and_update_in(user_state.data.geolocation.central_geohash, &{&1, geohash})
            {_prev, user_state} = get_and_update_in(user_state.data.location_type, &{&1, :home} )
            StateManager.set_state(telegram_id, user_state)
            # ExGram.send_message(telegram_id, Template.orb_creation_preview_builder(user_state.data),
            #   parse_mode: "HTML", reply_markup: Button.build_orb_create_keyboard_button())
          end
        end
      "work" ->
        if is_nil(user.private_profile) do
          ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: "work"}),
            parse_mode: "HTML", reply_markup: Button.build_location_specific_button("Work"))
        else
          geohash =
            case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == "work" end) do
              nil -> nil
              %{geohash: geohash} -> geohash
            end
          if is_nil(geohash) do
            ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: "work"}),
              parse_mode: "HTML", reply_markup: Button.build_location_specific_button("Work"))
          else
            {_prev, user_state} = get_and_update_in(user_state.data.geolocation.central_geohash, &{&1, geohash})
            {_prev, user_state} = get_and_update_in(user_state.data.location_type, &{&1, :work} )
            StateManager.set_state(telegram_id, user_state)
            # ExGram.send_message(telegram_id, Template.orb_creation_preview_builder(user_state.data),
            #   parse_mode: "HTML", reply_markup: Button.build_orb_create_keyboard_button())
          end
        end
      "live" ->
        ExGram.send_message(telegram_id, "Send your live location with the paperclip icon below.", parse_mode: "HTML")
      end

    user_state = StateManager.get_state(telegram_id)
    case Fsmx.transition(user_state, "createorb_media") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "You must choose a location to post to.")
        IO.inspect(err)
    end
  end

  def create_orb_path(%{integrations: %{telegram_chat_id: telegram_id}} = user, :media) do
    user_state = StateManager.get_state(telegram_id)
    case Fsmx.transition(user_state, "createorb_media") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "Something went wrong.")
        IO.inspect(err)
    end
  end

  def create_orb_path_transition(%{integrations: %{telegram_chat_id: telegram_id}} = user, :media, payload) do
    user_state = StateManager.get_state(telegram_id)
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

    # ExGram.send_photo(telegram_id, payload |> get_in(["photo"]) |> Enum.reverse() |> List.first() |> get_in(["file_id"]),
    #   caption: "Media ##{mediacount - 1} attached!\n" <> Template.orb_creation_preview_builder(user_state.data),
    #   parse_mode: "HTML", reply_markup: Button.build_orb_create_keyboard_button())

    case Fsmx.transition(user_state, "createorb_preview") do
      {:ok, _} ->
        StateManager.set_state(telegram_id, user_state)
        ExGram.send_message(telegram_id, Template.orb_creation_preview_builder(user_state.data),
          parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
      {:error, err} ->
        ExGram.send_message(telegram_id, "You must fill in a description and location to post!")
    end
  end

  def create_orb_path_transition(%{integrations: %{telegram_chat_id: telegram_id}} = user, :preview) do
    user_state = StateManager.get_state(telegram_id)
    case Fsmx.transition(user_state, "createorb_preview") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "Something went wrong.")
        IO.inspect(err)
    end
  end

  def create_orb_path(%{integrations: %{telegram_chat_id: telegram_id}} = user, :post) do
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
        {:ok, media} <- Phos.Orbject.Structure.apply_media_changeset(%{id: attrs["id"], archetype: "ORB",
          media: user_state.data.media}),
        {:ok, %Phos.Action.Orb{} = orb} <- Phos.Action.create_orb(%{attrs | "media" => true}) do
            TN.Collector.add(orb)
            ExGram.send_message(telegram_id, "Orb created successfully!")
            StateManager.delete_state(telegram_id)
        else
          err ->
            IO.inspect(user_state.data.media)
            IO.inspect(err)
            ExGram.send_message(telegram_id, "Please ensure you have filled in all the required fields.")
            ExGram.send_message(telegram_id, Template.orb_creation_preview_builder(user_state.data),
              parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
    end
  end


  def createorb_print_description_text(telegram_id) do
    {:ok, user} = Phos.TeleBot.get_user_by_telegram(telegram_id)
    ExGram.send_message(telegram_id, Template.orb_creation_description_builder(%{}),
      parse_mode: "HTML", reply_markup: Button.build_createorb_description_inlinekeyboard())
  end

  def createorb_print_location_text(telegram_id) do
    {:ok, user} = Phos.TeleBot.get_user_by_telegram(telegram_id)
    ExGram.send_message(telegram_id, "Great! Where should we post to?", parse_mode: "HTML",
      reply_markup: Button.build_createorb_location_inlinekeyboard(user))
  end

  def createorb_print_media_text(telegram_id) do
    {:ok, user} = Phos.TeleBot.get_user_by_telegram(telegram_id)
    ExGram.send_message(telegram_id, "Almost there! Add an image to make things interesting?\n<i>(Use the 📎 button to attach image)</i>",
      parse_mode: "HTML", reply_markup: Button.build_createorb_media_inlinekeyboard())
  end

  def createorb_print_preview_text(telegram_id) do
    {:ok, user} = Phos.TeleBot.get_user_by_telegram(telegram_id)
    user_state = StateManager.get_state(telegram_id)
    ExGram.send_message(telegram_id, Template.orb_creation_preview_builder(user_state.data),
      parse_mode: "HTML", reply_markup: Button.build_createorb_preview_inlinekeyboard())
  end
end
