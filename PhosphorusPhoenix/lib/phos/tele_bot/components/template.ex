defmodule Phos.TeleBot.Components.Template do
  use Phoenix.Component
  import PhosWeb.Endpoint, only: [url: 0]
  use PhosWeb, :html

  def start_menu_text_builder(assigns) do
    ~H"""
    <b>About us!</b>

    Our goal is to help people stay connected with their community. We want to help people find out what's happening around them, and to help them share their thoughts and feelings with their community.

    Press /start or /menu if bot hangs
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def main_menu_text_builder(assigns) do
    ~H"""
    Welcome to the ScratchBac Telegram Bot!

    <u>Announcements</u>
      - Telegram Bot is now live!
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def help_text_builder(assigns) do
    ~H"""
    Here is your inline command help:
      1. /start - To start using the bot

      Additional information
      - /help - Show this help
      - /post - Post something
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def onboarding_text_builder(assigns) do
    ~H"""
    Welcome to the ScratchBac Telegram Bot!

    Set your location now to hear what's happening around you! You need to /register to use all our features (/profile, /post).
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def incomplete_profile_text_builder(assigns) do
    ~H"""
    Hold on! Are you a robot? Please complete your profile before posting.

    You still have not set your: <%= if not @username do %>Username<% end %><%= if not @profile_picture do %> Profile Picture<% end %>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def latest_posts_text_builder(assigns) do
    ~H"""
    <b>Which posts would you like to view</b>

    You can also use the /post command to post something.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def update_location_text_builder(assigns) do
    ~H"""
    <b>You have not set your <%= @location_type %> location</b>

    Please update your location by clicking the button below.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def orb_creation_description_builder(assigns) do
    ~H"""
    <b>Type and send your post description below.</b> <i>(max 300 characters)</i>

    Here's an example:
    📢 : Open Jio SUPPER! Hosting a prata night this Saturday @ 8pm, anyone can come!
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def orb_creation_media_builder(assigns) do
    ~H"""
    <b>Attach a media to go along with your post.</b> <i>(pictures, gifs, videos)</i>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def orb_creation_location_builder(assigns) do
    ~H"""
    <b>Where should we send this post to?</b>

    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def orb_creation_preview_builder(assigns) do
    ~H"""
    <b>Preview your post</b> <i>(You can edit your post)</i>

    📍 <b>Posting to: </b><%= to_string(@location_type) %>
    📋 <b>What's happening today?</b>
    <%= @inner_title %>
    <%!-- 💚 <b>Info:</b> <%= @info %> --%>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def orb_telegram_orb_builder(assigns) do
    ~H"""
    📋 <b>Inner Title:</b> <%= @payload.inner_title %>

    👤 From:
    <%!-- 💚 <b>Info:</b> <%= @payload.info %> --%>
    <%!-- 💜 <b>By:</b> <% if is_nil(@initiator.username), do: %><a href={"tg://user?id=#{@telegram_user["id"]}"}>@<%= @telegram_user["username"] %></a> <% , else: %> <%= @initiator.username %> --%>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def profile_text_builder(assigns) do
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
        %{location_description: description} ->
          # remove any digits and set the description to uppcase
          Regex.replace(~r/\d+/, description, "") |> String.upcase()
      end
    else
      "Not set"
    end
  end
end
