defmodule Phos.TeleBot.CreateOrb do
  alias Phos.TeleBot.Core, as: BotCore
  alias Phos.TeleBot.{Config, StateManager}
  alias Phos.TeleBot.Components.{Button, Template}
  alias Phos.TeleBot.TelegramNotification, as: TN

  def create_fresh_orb_form(telegram_id) do
    {:ok, user_state} = StateManager.new_state(telegram_id)
    user_state
    |> Map.put(:branch, %Phos.TeleBot.CreateOrbFSM{telegram_id: telegram_id, state: "description"})
    |> StateManager.update_state(telegram_id)
    ExGram.send_message(telegram_id, Template.orb_creation_description_builder(%{}),
      parse_mode: "HTML", reply_markup: Button.build_main_menu_inlinekeyboard())
  end

  def set_description(branch, text) do
    {_prev, branch} = get_and_update_in(branch.data.orb.payload.inner_title, &{&1, text} )
    transition(branch, "location")
  end

  def set_location(branch, location_type) when location_type in ["home", "work"] do
    {:ok, user} = BotCore.get_user_by_telegram(branch.telegram_id)
    if is_nil(user.private_profile) do
      send_location_update_message(branch.telegram_id, location_type)
    else
      geohash =
        case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == location_type end) do
          nil -> nil
          %{geohash: geohash} -> geohash
        end
      if geohash do
        {_prev, branch} = get_and_update_in(branch.data.orb.central_geohash, &{&1, geohash})
        {_prev, branch} = get_and_update_in(branch.data.location_type, &{&1, String.to_atom(location_type)} )
        transition(branch, "media")
      else
        send_location_update_message(branch.telegram_id, location_type)
      end
    end
  end
  def set_location(%{telegram_id: telegram_id} = branch, text) do
    ExGram.send_message(telegram_id, "Please use the location button to select.")
  end
  def set_location(branch, location_type, opts) when location_type in ["live"] do
    latlon = opts[:latlon]
    {:ok, user} = BotCore.get_user_by_telegram(branch.telegram_id)
    {_prev, branch} = get_and_update_in(branch.data.orb.central_geohash, &{&1, :h3.from_geo(latlon, 10)} )
    {_prev, branch} = get_and_update_in(branch.data.location_type, &{&1, String.to_atom(location_type)} )
    transition(branch, "media")
  end

  def set_picture(%{tele_id: telegram_id} = user, payload) do
    {:ok, %{branch: branch} = user_state} = StateManager.get_state(telegram_id)
    orb_id = Ecto.UUID.generate()
    media_map = [%{
      "access": "public",
      "essence": "banner"
    }]
    with {:ok, media_change} <- Phos.Orbject.Structure.apply_media_changeset(%{id: user.id, archetype: "ORB", media: media_map}) do
      resolution = %{"150x150" => "public/banner/lossy", "1920x1080" => "public/banner/lossless"}
      for res <- ["150x150", "1920x1080"] do
        {:ok, dest} = Phos.Orbject.S3.put("ORB", orb_id , resolution[res])
        [hd | tail] = payload |> get_in(["photo"]) |> Enum.reverse()
        {:ok, %{file_path: path}} = ExGram.get_file(hd |> get_in(["file_id"]))
        {:ok, %HTTPoison.Response{body: image}} = HTTPoison.get("https://api.telegram.org/file/bot#{Config.get(:bot_token)}/#{path}")
        path = "/tmp/" <> (:crypto.strong_rand_bytes(30) |> Base.url_encode64()) <> ".png"
        File.write!(path , image)
        HTTPoison.put(dest, {:file, path})
        File.rm(path)
      end
      {_prev, branch} = get_and_update_in(branch.data.orb.id, &{&1, orb_id})
      {_prev, branch} = get_and_update_in(branch.data.media, &{&1, media_change})
      Map.put(user_state, :branch, branch)
      |> StateManager.update_state(telegram_id)
      transition(branch, "preview")
    else
      err -> BotCore.error_fallback(telegram_id, err)
    end
  end

  # def set_video(%{tele_id: telegram_id} = user, payload) do
  #   {:ok, %{branch: branch} = user_state} = StateManager.get_state(telegram_id)
  #   orb_id = Ecto.UUID.generate()
  #   media_map = [%{
  #     "access": "public",
  #     "essence": "banner"
  #   }]
  #   with {:ok, media_change} <- Phos.Orbject.Structure.apply_media_changeset(%{id: user.id, archetype: "ORB", media: media_map}) do
  #     resolution = %{"150x150" => "public/banner/lossy", "1920x1080" => "public/banner/lossless"}
  #     for res <- ["150x150", "1920x1080"] do
  #       {:ok, dest} = Phos.Orbject.S3.put("ORB", orb_id , resolution[res])
  #       {:ok, %{file_path: path}} = ExGram.get_file(payload |> get_in(["video", "file_id"]))
  #       {:ok, %HTTPoison.Response{body: video}} = HTTPoison.get("https://api.telegram.org/file/bot#{Config.get(:bot_token)}/#{path}")
  #       path = "/tmp/" <> (:crypto.strong_rand_bytes(30) |> Base.url_encode64()) <> ".mp4"
  #       File.write!(path , video)
  #       HTTPoison.put(dest, {:file, path})
  #       File.rm(path)
  #     end
  #     {_prev, branch} = get_and_update_in(branch.data.orb.id, &{&1, orb_id})
  #     {_prev, branch} = get_and_update_in(branch.data.media, &{&1, media_change})
  #     Map.put(user_state, :branch, branch)
  #     |> StateManager.update_state(telegram_id)
  #     transition(branch, "preview")
  #   else
  #     err -> BotCore.error_fallback(telegram_id, err)
  #   end
  # end

  def post(%{data: %{orb: orb, media: %{media: media}}} = branch, %{tele_id: telegram_id} = user) do
    params = %{
      "id" => orb.id,
      "expires_in" => "10000",
      "title" => orb.payload.inner_title |> String.slice(0, 50),
      "media" => media,
      "inner_title" => orb.payload.inner_title,
      "active" => true,
      "source" => :api,
      "geolocation" => %{"central_geohash" => orb.central_geohash}
    }

    with {:ok, attrs} <- PhosWeb.API.OrbController.orb_constructor(user, params),
        {:ok, %Phos.Action.Orb{} = orb} <- Phos.Action.create_orb(%{attrs | "media" => not Enum.empty?(media)}) do
            ExGram.send_message(telegram_id, "Creating post...")
            StateManager.delete_state(telegram_id)
        else
          err -> BotCore.error_fallback(telegram_id, err)
    end
  end

  def send_location_update_message(telegram_id, location_type) do
    ExGram.send_message(telegram_id, Template.update_location_text_builder(%{location_type: location_type}),
          parse_mode: "HTML", reply_markup: Button.build_location_specific_button(location_type))
  end

  def transition(branch, destination) do
    with {:ok, user_state} <- StateManager.get_state(branch.telegram_id),
         {:ok, next_state} <- Fsmx.transition(branch, destination) do
          user_state
          |> Map.put(:branch, next_state)
          |> StateManager.update_state(branch.telegram_id)
    else
      {:error, err} ->
        BotCore.error_fallback(branch.telegram_id, err)
    end
  end
end
