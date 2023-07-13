defmodule Phos.TeleBot.Components.Button do
  alias Phos.TeleBot.Components.Template

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

  def build_onboarding_register_button() do
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

  def build_start_inlinekeyboard(message_id) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "📔 Main Menu", callback_data: "start_mainmenu" <> to_string(message_id)},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "FAQ", callback_data: "start_faq" <> to_string(message_id)},
        %ExGram.Model.InlineKeyboardButton{text: "Feedback", callback_data: "start_feedback" <> to_string(message_id)},
      ]
      ]}
  end

  def build_menu_inlinekeyboard(), do: build_menu_inlinekeyboard("")
  def build_menu_inlinekeyboard(message_id) do
    # %ExGram.Model.ReplyKeyboardMarkup{resize_keyboard: true, keyboard:  [
    #   [
    #     %ExGram.Model.KeyboardButton{text: "🔭 Latest Posts"},
    #   ],
    #   [
    #     %ExGram.Model.KeyboardButton{text: "👤 Profile"},
    #     %ExGram.Model.KeyboardButton{text: "❓ Help"},
    #   ]
    # ]}
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "✈️ Post", callback_data: "menu_post"},
        %ExGram.Model.InlineKeyboardButton{text: "🔭 View Latest Posts", callback_data: "menu_latestposts" <> to_string(message_id)},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "👤 Profile", callback_data: "menu_openprofile" <> to_string(message_id)},
        %ExGram.Model.InlineKeyboardButton{text: "📕 My Posts", switch_inline_query_current_chat: "myposts"},
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

  def build_settings_button(), do: build_settings_button("")
  def build_settings_button(message_id) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Edit Name", callback_data: "edit_profile_name" <> to_string(message_id)},
        %ExGram.Model.InlineKeyboardButton{text: "Edit Bio", callback_data: "edit_profile_bio" <> to_string(message_id)},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "Set Location", callback_data: "edit_profile_location" <> to_string(message_id)},
        %ExGram.Model.InlineKeyboardButton{text: "Edit Picture", callback_data: "edit_profile_picture" <> to_string(message_id)},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "📔 Main Menu", callback_data: "start_mainmenu" <> to_string(message_id)},
      ]
      ]}
  end

  def build_link_account_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "🔗 Link Account", callback_data: "link_account"},
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

  def build_location_button(user), do: build_location_button(user, "")
  def build_location_button(user, message_id) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Home: " <> Template.get_location_desc_from_user(user, "home"), callback_data: "edit_profile_locationtype_home"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "Work: " <> Template.get_location_desc_from_user(user, "work"), callback_data: "edit_profile_locationtype_work"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "Live: " <> Template.get_location_desc_from_user(user, "live"), callback_data: "edit_profile_locationtype_live"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "📔 Main Menu", callback_data: "start_mainmenu" <> to_string(message_id)},
      ]
      ]}
    # %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [[
    #   %ExGram.Model.InlineKeyboardButton{text: "Home", callback_data: "edit_profile_locationtype_home"},
    #   %ExGram.Model.InlineKeyboardButton{text: "Work", callback_data: "edit_profile_locationtype_work"},
    #   %ExGram.Model.InlineKeyboardButton{text: "Live", callback_data: "edit_profile_locationtype_live"},
    # ]]}
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

  def build_existing_post_creation_inline_button() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Continue", callback_data: "createorb_continue"},
        %ExGram.Model.InlineKeyboardButton{text: "Restart", callback_data: "createorb_restart"},
      ]
      ]}
  end

  def build_latest_posts_inline_button(), do: build_latest_posts_inline_button("")
  def build_latest_posts_inline_button(message_id) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Home", switch_inline_query_current_chat: "home"},
        %ExGram.Model.InlineKeyboardButton{text: "Work", switch_inline_query_current_chat: "work"},
        %ExGram.Model.InlineKeyboardButton{text: "Live", switch_inline_query_current_chat: "live"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "📔 Main Menu", callback_data: "start_mainmenu" <> to_string(message_id)},
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

  # def build_cancel_button() do
  #   %ExGram.Model.ReplyKeyboardMarkup{resize_keyboard: true, keyboard:  [[
  #     %ExGram.Model.KeyboardButton{text: "❌ Cancel"}
  #   ]]}
  # end

  def build_orb_notification_button(orb) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        # %ExGram.Model.InlineKeyboardButton{text: "💬 Message User", callback_data: "orb_message_user#{orb.id}"},
        %ExGram.Model.InlineKeyboardButton{text: "Open on Web", url: "https://nyx.scrb.ac/orb/#{orb.id}"},
      ]
    ]}
  end

  def build_main_menu_inlinekeyboard(), do: build_main_menu_inlinekeyboard("")
  def build_main_menu_inlinekeyboard(message_id) do
    # %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: false, resize_keyboard: true, keyboard:  [
    #   [
    #     %ExGram.Model.KeyboardButton{text: "📎 Media"},
    #     %ExGram.Model.KeyboardButton{text: "📍 Location"},
    #   ],
    #   [
    #     %ExGram.Model.KeyboardButton{text: "❌ Cancel"},
    #     %ExGram.Model.KeyboardButton{text: "✈️ Post"},
    #   ]
    # ]}
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "📔 Main Menu", callback_data: "start_mainmenu" <> to_string(message_id)},
      ]
      ]}
  end

  def build_createorb_location_inlinekeyboard(user) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "Home: " <> Template.get_location_desc_from_user(user, "home"), callback_data: "createorb_location_home"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "Work: " <> Template.get_location_desc_from_user(user, "work"), callback_data: "createorb_location_work"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "Live: " <> Template.get_location_desc_from_user(user, "live"), callback_data: "createorb_location_live"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "📔 Main Menu", callback_data: "start_mainmenu"},
        %ExGram.Model.InlineKeyboardButton{text: "↩️ Back", callback_data: "createorb_back_description"},
      ]
      ]}
  end

  def build_createorb_media_inlinekeyboard() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "📔 Main Menu", callback_data: "start_mainmenu"},
        %ExGram.Model.InlineKeyboardButton{text: "↩️ Back", callback_data: "createorb_back_location"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "⏭️ Skip", callback_data: "createorb_preview"},
      ]
      ]}
  end

  def build_createorb_preview_inlinekeyboard() do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
      [
        %ExGram.Model.InlineKeyboardButton{text: "📔 Main Menu", callback_data: "start_mainmenu"},
        %ExGram.Model.InlineKeyboardButton{text: "↩️ Back", callback_data: "createorb_back_media"},
      ],
      [
        %ExGram.Model.InlineKeyboardButton{text: "✈️ Post", callback_data: "createorb_post"},
      ]
      ]}
  end

  # def build_createorb_location_button() do
  #   %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: true, resize_keyboard: true, keyboard:  [[
  #     %ExGram.Model.KeyboardButton{text: "🏡 Home"},
  #     %ExGram.Model.KeyboardButton{text: "🏢 Work"},
  #     %ExGram.Model.KeyboardButton{text: "📍 Live", request_location: true}
  #   ]]}
  # end

  # def build_createorb__location_inlinekeyboard(%{home: home_desc, work: work_desc, live: live_desc} = payload) do
  #   %ExGram.Model.InlineKeyboardMarkup{inline_keyboard:  [
  #     [
  #       %ExGram.Model.InlineKeyboardButton{text: "#1: " <> home_desc, callback_data: "createorb_location_home"},
  #     ],
  #     [
  #       %ExGram.Model.InlineKeyboardButton{text: "#2 : " <> work_desc, callback_data: "createorb_location_work"},
  #     ],
  #     [
  #       %ExGram.Model.InlineKeyboardButton{text: live_desc, callback_data: "createorb_location_live"},
  #     ]
  #     ]}
  # end
end
