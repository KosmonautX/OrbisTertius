defmodule Phos.TeleBot do
  @bot :phos_telebot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  alias Phos.Users
  alias __MODULE__.{Config, Remainder}

  command("start", description: "Start the interactive bot")
  command("help", description: "Print the bot's help")
  command("menu", description: "Show menu buttons")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  def handle({:command, :start, %{chat: chat} = _msg}, context) do
    get_in(chat, [:id])
    |> Users.telegram_user_exists?()
    |> case do
      false -> registration_menu(context)
      _ -> main_menu(context)
    end
  end

  def handle({:command, :menu, _msg}, context) do
    texts = [
      "ScratchBac Telegram Bot Menu",
      "You can choose one of the button",
      "Right now, you can set your location and edit the SB personal data"
    ]

    answer(context, Enum.join(texts, "\n"), reply_markup: build_menu_button())
  end

  def handle({:command, :help, _msg}, context) do
    helps = [
      "Here is your inline command help:",
      "1. /start - To start a conversation",
      "\n",
      "Additional information",
      "- /help - Show this help",
      "- /menu - Interactive menu buttons",
    ]

    answer(context, Enum.join(helps, "\n"))
  end

  def handle({:callback_query, %{data: "location"}}, context) do
    texts = [
      "You can set up your home, work and live location",
      "Just send your pinned location or live location after hitting the button",
    ]

    answer(context, Enum.join(texts, "\n"), reply_markup: build_location_button())
  end

  def handle({:callback_query, %{data: "location_" <> type }}, %{update: update} = context) when type in ["home", "work", "live"] do
    text = "Please send your #{type} location"
    update
    |> Map.from_struct()
    |> get_in([:callback_query, :message, :chat, :id])
    |> Remainder.set_location(type)

    answer(context, text)
  end

  def handle({:location, %{latitude: lat, longitude: lon}},%{update: update} = context) do
    telegram_id = 
      update
      |> Map.from_struct()
      |> get_in([:message, :chat, :id])
    case Phos.Users.get_user_by_telegram(to_string(telegram_id)) do
      {:ok, user} -> update_user_location(context, telegram_id, user, {lat, lon})
      _ -> answer(context, "Your #{Remainder.get_location(telegram_id)} not set.")
    end
  end

  def handle({:bot_message, to, %Phos.Action.Orb{} = orb}, _context) do
    text = case orb.media do
      true ->
        url = Phos.Orbject.S3.get!("ORB", orb.id, "public/banner/lossless")
        "#{url}\n\n#{orb_telegram_text_creator(orb)}"
      _ -> orb_telegram_text_creator(orb)
    end
    ExGram.send_message(to, text, reply_markup: build_orb_notification_button())
  end

  def build_menu_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
      %ExGram.Model.InlineKeyboardButton{text: "Set Location", callback_data: "location"},
      %ExGram.Model.InlineKeyboardButton{text: "Edit Data", callback_data: "edit"},
    ]]}
  end

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

  defp build_location_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
      %ExGram.Model.InlineKeyboardButton{text: "Set Home Location", callback_data: "location_home"},
      %ExGram.Model.InlineKeyboardButton{text: "Set Work Location", callback_data: "location_work"},
      %ExGram.Model.InlineKeyboardButton{text: "Set Live Location", callback_data: "location_live"},
    ]]}
  end

  defp build_orb_notification_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "💬 Message User", callback_data: "orb_message_user"},
        %ExGram.Model.InlineKeyboardButton{text: "♥️  Like", callback_data: "orb_like"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "🙈 Hide", callback_data: "orb_hide"},
        %ExGram.Model.InlineKeyboardButton{text: "More ...", callback_data: "orb_more"},
      ],
    ]}
  end

  defp registration_menu(context) do
    texts = [
      "Hi",
      "Welcome to ScratchBac Telegram Bot.",
      "You can posting register and posting an orb and join with the community.",
      "To register click the link below",
      "\n",
      "Thanks.",
      "ScratchBac Team."
    ]

    answer(context, Enum.join(texts, "\n"), reply_markup: build_registration_button())
  end

  defp main_menu(context) do
    texts = [
      "Hi",
      "Welcome to ScratchBac Telegram Bot.",
      "You can posting an orb set your location and etc.",
      "\n",
      "Thanks.",
      "ScratchBac Team."
    ]

    answer(context, Enum.join(texts, "\n"), reply_markup: build_menu_button())
  end

  defp update_user_location(context, telegram_id, user, geo) do
    type = Remainder.get_location(telegram_id)
    validate_user_update_location(context, type, telegram_id, user, geo)
  end

  defp validate_user_update_location(context, nil, _, _, _), do: answer(context, "You must set your location type")
  defp validate_user_update_location(context, type, telegram_id, %{private_profile: priv} = user, geo) do
    geos = Map.get(priv, :geolocation, []) |> Enum.map(&Map.from_struct(&1) |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, to_string(k), v) end)) |> Enum.reduce([], fn loc, acc ->
      case Map.get(loc, "id") == type do
        true -> acc
        _ -> [loc | acc]
      end
    end)

    Remainder.remove_location(telegram_id)
    case Phos.Users.update_territorial_user(user, %{private_profile: %{user_id: user.id, geolocation: [%{"id" => type, "geohash" => :h3.from_geo(geo, 8)} | geos]}}) do
      {:ok, _user} ->
        answer(context, "Your #{type} location is set")
      _ -> answer(context, "Your #{type} location is not set.")
    end
  end

  defp orb_telegram_text_creator(%{payload: payload} = orb) do
    inner_title = Map.get(payload, :inner_title, "")
    title = "💙 Title: " <> payload_getter(orb, :title, inner_title)
    where = "💚 Where: " <> payload_getter(payload, :where, "-")
    date = "💛 When: " <> payload_getter(payload, :when, "-")
    tip = "🧡 Tip: " <> payload_getter(payload, :tip, "-")
    initiator = "By: [[ #{orb.initiator.username} ]]"
    level = "Level: ✨"

    [title, "\n", where, date, tip, "\n", initiator, level]
    |> Enum.join("\n")
  end

  defp payload_getter(payload, type, default) do
    case Map.get(payload, type) do
      nil -> default
      data -> data
    end
  end
end
