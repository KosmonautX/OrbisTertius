defmodule Phos.TeleBot.CreateOrbPath do
  alias Phos.TeleBot.{Config, StateManager}
  alias Phos.TeleBot.Components.{Button, Template}

  alias Phos.TeleBot.TelegramNotification, as: TN

  def create_orb_path(%{integrations: %{telegram_chat_id: nil}} = user, _), do: IO.inspect("User does not have telegram_id..")
  def create_orb_path_transition(%{integrations: %{telegram_chat_id: nil}} = user, _), do: IO.inspect("User does not have telegram_id..")
  def create_orb_path_transition(%{integrations: %{telegram_chat_id: nil}} = user, _, _), do: IO.inspect("User does not have telegram_id..")

  def create_orb_path(%{integrations: %{telegram_chat_id: telegram_id}} = user, :description) do
    user_state = StateManager.get_state(telegram_id)
    case Fsmx.transition(user_state, "createorb_description") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "Something went wrong. Please /start again.")
        IO.inspect(err)
    end
  end

  def create_orb_path_transition(%{integrations: %{telegram_chat_id: telegram_id}} = user, :description, text) do
    user_state = StateManager.get_state(telegram_id)
    {_prev, user_state} = get_and_update_in(user_state.data.inner_title, &{&1, text})

    case Fsmx.transition(user_state, "createorb_location") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "You must type a description for your post.")
    end
  end

  def create_orb_path(%{integrations: %{telegram_chat_id: telegram_id}} = user, :location) do
    user_state = StateManager.get_state(telegram_id)
    case Fsmx.transition(user_state, "createorb_location") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "Something went wrong. Please /start again.")
        IO.inspect(err)
    end
  end

  def create_orb_path_transition(%{integrations: %{telegram_chat_id: telegram_id}} = user, :location, type) do
    user_state = StateManager.get_state(telegram_id)

    case type do
      "home" ->
        handle_locaton_transaction(user_state, user, telegram_id, "home")
      "work" ->
        handle_locaton_transaction(user_state, user, telegram_id, "work")
      "live" ->
        case Fsmx.transition(user_state, "createorb_current_location") do
          {:ok, user_state} ->
            StateManager.set_state(telegram_id, user_state)
          {:error, err} ->
            ExGram.send_message(telegram_id, "Transition error")
            IO.inspect(err)
        end
      end
  end

  def handle_locaton_transaction(user_state, user, telegram_id, location_type) do
    if is_nil(user.private_profile) do
      send_location_update_message(telegram_id, location_type)
    else
      geohash =
        case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == location_type end) do
          nil -> nil
          %{geohash: geohash} -> geohash
        end
      if is_nil(geohash) do
        send_location_update_message(telegram_id, location_type)
      else
        {_prev, user_state} = get_and_update_in(user_state.data.geolocation.central_geohash, &{&1, geohash})
        {_prev, user_state} = get_and_update_in(user_state.data.location_type, &{&1, location_type} )
        StateManager.set_state(telegram_id, user_state)
        user_state = StateManager.get_state(telegram_id)
        case Fsmx.transition(user_state, "createorb_media") do
          {:ok, user_state} ->
            StateManager.set_state(telegram_id, user_state)
          {:error, err} ->
            ExGram.send_message(telegram_id, "You must choose a location to post to.")
            IO.inspect(err)
        end
      end
    end
  end

  def send_location_update_message(telegram_id, location_type) do
    ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: location_type}),
          parse_mode: "HTML", reply_markup: Button.build_location_specific_button(location_type))
  end

  def create_orb_path_transition(%{integrations: %{telegram_chat_id: telegram_id}} = user, :current_location) do
    user_state = StateManager.get_state(telegram_id)
    case Fsmx.transition(user_state, "createorb_media") do
      {:ok, user_state} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "Something went wrong.")
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
    media = [%{
      access: "public",
      essence: "profile",
      resolution: "lossy",
      count: 1
    }]
    with {:ok, media} <- Phos.Orbject.Structure.apply_media_changeset(%{id: user.id, archetype: "ORB", media: media}) do
      resolution = %{"150x150" => "lossy", "1920x1080" => "lossless"}
      for res <- ["150x150", "1920x1080"] do
        {:ok, dest} = Phos.Orbject.S3.put("ORB", user.id, "public/profile/#{resolution[res]}")
        [hd | tail] = payload |> get_in(["photo"]) |> Enum.reverse()
        {:ok, %{file_path: path}} = ExGram.get_file(hd |> get_in(["file_id"]))
        {:ok, %HTTPoison.Response{body: image}} = HTTPoison.get("https://api.telegram.org/file/bot#{Config.get(:bot_token)}/#{path}")
        path = "/tmp/" <> (:crypto.strong_rand_bytes(30) |> Base.url_encode64()) <> ".png"
        File.write!(path , image)
        HTTPoison.put(dest, {:file, path})
        File.rm(path)
      end
    else
      err ->
        IO.inspect("Something went wrong: set_orb_picture #{err}")
    end

    {_prev, user_state} = get_and_update_in(user_state.data.media, &{&1, media})
    StateManager.set_state(telegram_id, user_state)

    case Fsmx.transition(user_state, "createorb_preview") do
      {:ok, _} ->
        StateManager.set_state(telegram_id, user_state)
      {:error, err} ->
        ExGram.send_message(telegram_id, "You must type a post <u>description</u> and <u>set a location</u> to post to before uploading a photo!", parse_mode: "HTML")
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
    IO.inspect(user_state)
    case user_state do
      %{data: %{inner_title: inner_title, media: media, geolocation: %{central_geohash: central_geohash}}} ->
        params = %{
          "id" => Ecto.UUID.generate(),
          "expires_in" => "10000",
          "title" => inner_title |> String.slice(0, 50),
          "media" => media,
          "inner_title" => inner_title,
          "active" => true,
          "source" => :tele,
          "geolocation" => %{"central_geohash" => central_geohash}
        }

        with {:ok, attrs} <- PhosWeb.API.OrbController.orb_constructor(user, params),
            {:ok, %Phos.Action.Orb{} = orb} <- Phos.Action.create_orb(%{attrs | "media" => not Enum.empty?(user_state.data.media)}) do
                TN.Collector.add(orb)
                ExGram.send_message(telegram_id, "Creating post..")
                StateManager.delete_state(telegram_id)
            else
              err ->
                IO.inspect(err)
                ExGram.send_message(telegram_id, "Please ensure you have filled in all the required fields.")
        end
      _ ->
        ExGram.send_message(telegram_id, "Something went wrong. Please run /start again.")
    end
  end
end
