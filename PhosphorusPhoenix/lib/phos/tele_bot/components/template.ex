defmodule Phos.TeleBot.Components.Template do
  use Phoenix.Component
  import PhosWeb.Endpoint, only: [url: 0]
  use PhosWeb, :html

  def start_menu_text_builder(assigns) do
    ~H"""
    <b>👋 About us!</b>

    Our goal is to help people stay connected with their community. We want to help people find out what's happening around them, and to help them share their thoughts and feelings with their community.

    ↙️ To navigate around this bot, use the Menu button on the bottom left corner.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def main_menu_text_builder(assigns) do
    ~H"""
    Welcome to the ScratchBac Telegram Bot!

    <u>📢 Announcements</u>
      - Telegram Bot is now live!

    ↙️ To navigate around this bot, use the Menu button on the bottom left corner.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def not_yet_registered_text_builder(assigns) do
    ~H"""
    We have so many features here and can't wait for you to join us but
    you need to be verified to use them.

    <u>Click on the "Register" button</u>

    <i>Note: If you have already registered, do check your email or /register again</i>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def onboarding_register_text_builder(assigns) do
    ~H"""
    <b>What is your email?</b>

    Please provide us with a valid email, you will receive a confirmation email to confirm your registration.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def help_text_builder(assigns) do
    ~H"""
    Here is your inline help:
      1. /start - To start using the bot

      Additional information
      - /help - Show this help
      - /post - Post to a location
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def faq_text_builder(assigns) do
    ~H"""
    Is my location saved?
    - No, we take a general location from you (1km), we do not save any location specific data even though we collect your postal code.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def feedback_text_builder(assigns) do
    ~H"""
    You can directly message our admin @Scratchbac_Admin to give feedback.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def onboarding_text_builder(assigns) do
    ~H"""
    <b>About us!</b>

    Our goal is to help people stay connected with their community. We want to help people find out what's happening around them, and to help them share their thoughts and feelings with their community.

    <u>You need to /register to use all our features such as /post</u>

    <i>Or.. you can start receiving posts by setting your location! <b>Main Menu > Profile > Set Location</b></i>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def incomplete_profile_text_builder(assigns) do
    ~H"""
    Hold on! Are you a robot? Finish your profile to start posting.

    <u>Click on the "Complete Profile" button.</u>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def latest_posts_text_builder(assigns) do
    ~H"""
    <b>Which posts would you like to view</b>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def update_location_text_builder(assigns) do
    ~H"""
    <b>You have not set your <%= @location_type %> location</b>

    <u>Click on the button below to update it.</u>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def orb_creation_description_builder(assigns) do
    ~H"""
    <b>Type your post description and send.</b>

    Here's an example:
    Open Jio SUPPER! Hosting a prata night this Saturday @ 8pm, anyone can come!
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
    <b><u>Preview your post</u></b>

    📍 <b>Posting to: </b><%= to_string(@location_type) %>
    📋 <b>What's happening today?</b>
    <%= @orb.payload.inner_title %>
    <%!-- 💚 <b>Info:</b> <%= @info %> --%>

    <i>(You can edit your post by pressing ↩️ Back)</i>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def orb_telegram_orb_builder(assigns) do
    ~H"""
    📋 <b></b> <%= @payload.inner_title %>

    👤 From: <%= @initiator.username %>
    <%!-- 🔸Posted On: <%= @inserted_at |> DateTime.from_naive!("UTC") |> Timex.format("{D}-{0M}-{YYYY}") |> elem(1) %> --%>
    📍 <%= @central_geohash |> Phos.Mainland.World.locate() %>
    <%!-- 💚 <b>Info:</b> <%= @payload.info %> --%>
    <%!-- 💜 <b>By:</b> <% if is_nil(@initiator.username), do: %><a href={"tg://user?id=#{@telegram_user["id"]}"}>@<%= @telegram_user["username"] %></a> <% , else: %> <%= @initiator.username %> --%>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def profile_text_builder(assigns) do
    ~H"""
    🔸Name: <%= if @public_profile do %><%= @public_profile.public_name%><% else %>Not set<% end %>
    🔸Bio: <%= if @public_profile do %><%=@public_profile.bio%><% else %>Not set<% end %>
    🔸Join Date: <%= @inserted_at |> DateTime.from_naive!("UTC") |> Timex.format("{D}-{0M}-{YYYY}") |> elem(1) %>
    🔸Locations:
       1️⃣ <%= get_location_desc_from_user(assigns, "home") %>
       2️⃣ <%= get_location_desc_from_user(assigns, "work") %>
       🗺️ <%= get_location_desc_from_user(assigns, "live") %>

    <%= if @username do %>
    🔗 Share your profile:
    <%= PhosWeb.Endpoint.url %>/user/<%= @username %>
    <% end %>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def edit_profile_username_text_builder(assigns) do
    ~H"""
    <b>Choose a unique username.</b>

    The username should be
    - <u>5 characters long</u>
    - <u>letters and numbers</u>

    <b>Note: you will not be able to change your username after this set up.</b>
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  def get_location_desc_from_user(user, type) do
    if user.private_profile do
      case Enum.find(user.private_profile.geolocation, fn loc -> loc.id == type end) do
        nil -> "Not set"
        %{location_description: description} when not is_nil(description) ->
          description |> String.upcase()
        _ -> "Not set"
      end
    else
      "Not set"
    end
  end

  def fallback_text_builder(assigns) do
    ~H"""
    <b>Something went wrong...</b>

    Try again and contact @Scratchbac_admin if error keeps happening.
    """
    |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end
