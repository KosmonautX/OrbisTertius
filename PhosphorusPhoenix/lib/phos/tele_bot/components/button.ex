defmodule Phos.TeleBot.Components.Button do
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

  def build_choose_username_keyboard(username) do
    %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: true, resize_keyboard: true, keyboard:  [
      [
        %ExGram.Model.KeyboardButton{text: "#{username}"},
      ]
    ]}
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

  def build_location_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
      %ExGram.Model.InlineKeyboardButton{text: "Home", callback_data: "edit_profile_locationtype_home"},
      %ExGram.Model.InlineKeyboardButton{text: "Work", callback_data: "edit_profile_locationtype_work"},
      %ExGram.Model.InlineKeyboardButton{text: "Live", callback_data: "edit_profile_locationtype_live"},
    ]]}
  end

  def build_location_specific_button(loc_type) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
      %ExGram.Model.InlineKeyboardButton{text: "Set #{loc_type}", callback_data: "edit_profile_locationtype_#{String.downcase(loc_type)}"},
    ]]}
  end

  def build_current_location_button() do
    %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: true, resize_keyboard: true, keyboard:  [[
      %ExGram.Model.KeyboardButton{text: "Send Current Location", request_location: true}
    ]]}
  end

  def build_createorb_location_button() do
    %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: true, resize_keyboard: true, keyboard:  [[
      %ExGram.Model.KeyboardButton{text: "🏡 Home"},
      %ExGram.Model.KeyboardButton{text: "🏢 Work"},
      %ExGram.Model.KeyboardButton{text: "📍 Live", request_location: true}
    ]]}
  end

  def build_existing_post_creation_inline_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Continue", callback_data: "createorb_continue"},
        %ExGram.Model.InlineKeyboardButton{text: "Restart", callback_data: "createorb_restart"},
      ]
      ]}
  end

  def build_latest_posts_inline_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Home", switch_inline_query_current_chat: "home"},
        %ExGram.Model.InlineKeyboardButton{text: "Work", switch_inline_query_current_chat: "work"},
        %ExGram.Model.InlineKeyboardButton{text: "Live", switch_inline_query_current_chat: "live"},
      ]
      ]}
  end

  def build_preview_inline_button() do
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

  def build_orb_notification_button(orb) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        # %ExGram.Model.InlineKeyboardButton{text: "💬 Message User", callback_data: "orb_message_user#{orb.id}"},
        %ExGram.Model.InlineKeyboardButton{text: "Open on Web", url: "https://nyx.scrb.ac/orb/#{orb.id}"},
      ]
    ]}
  end

  def build_orb_create_keyboard_button() do
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
end
