defmodule Phos.TeleBot.Components.Button do
  alias Phos.TeleBot.Components.Template
  alias PhosWeb.Menshen.Auth

  def build_onboarding_register_button() do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "Register",
            [callback_data: "onboarding_register"]
          )
        ]
      ]
    )
  end

  def build_onboarding_username_button() do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "Complete Profile",
            [callback_data: "onboarding_username"]
          )
        ]
      ]
    )
  end

  def build_start_inlinekeyboard(message_id) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "📔 Main Menu",
            [callback_data: "start_mainmenu" <> to_string(message_id)]
          )
        ],
        [
          inline_keyboard_button(
            "FAQ",
            [callback_data: "start_faq" <> to_string(message_id)]
          ),
          inline_keyboard_button(
            "Feedback",
            [callback_data: "start_feedback" <> to_string(message_id)]
          )
        ]
      ]
    )
  end

  def build_menu_inlinekeyboard(), do: build_menu_inlinekeyboard("")
  def build_menu_inlinekeyboard(message_id) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "✈️ Post",
            [callback_data: "menu_post"]
          ),
          inline_keyboard_button(
            "🔭 View Latest Posts",
            [callback_data: "menu_latestposts" <> to_string(message_id)]
          )
        ],
        [
          inline_keyboard_button(
            "👤 Profile",
            [callback_data: "menu_openprofile" <> to_string(message_id)]
          ),
          inline_keyboard_button(
            "📕 My Posts",
            [switch_inline_query_current_chat: "myposts"]
          )
        ]
      ]
    )
  end

  def build_myposts_inlinekeyboard(), do: build_myposts_inlinekeyboard("")
  def build_myposts_inlinekeyboard(message_id) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "📕 My Posts",
            [switch_inline_query_current_chat: "myposts"]
          )
        ],
        [
          inline_keyboard_button(
            "📔 Main Menu",
            [callback_data: "start_mainmenu" <> to_string(message_id)]
          )
        ]
      ]
    )
  end

  def build_choose_username_keyboard(username) do
    reply_keyboard_markup(
      [
        [
          keyboard_button(
            username
          )
        ]
      ], [one_time_keyboard: true, resize_keyboard: true]
    )
    # %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: true, resize_keyboard: true, keyboard:  [
    #   [
    #     %ExGram.Model.KeyboardButton{text: "#{username}"},
    #   ]
    # ]}
  end

  def build_settings_button(), do: build_settings_button("")
  def build_settings_button(message_id) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "Edit Name",
            [callback_data: "edit_profile_name" <> to_string(message_id)]
          ),
          inline_keyboard_button(
            "Edit Bio",
            [callback_data: "edit_profile_bio" <> to_string(message_id)]
          )
        ],
        [
          inline_keyboard_button(
            "Set Location",
            [callback_data: "edit_profile_location" <> to_string(message_id)]
          ),
          inline_keyboard_button(
            "Edit Picture",
            [callback_data: "edit_profile_picture" <> to_string(message_id)]
          )
        ],
        [
          inline_keyboard_button(
            "📔 Main Menu",
            [callback_data: "start_mainmenu" <> to_string(message_id)]
          )
        ]
      ]
    )
  end

  def build_link_account_button() do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "🔗 Link Account",
            [callback_data: "onboarding_linkaccount"]
          )
        ]
      ]
    )
  end

  def build_help_button() do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "Guidelines",
            [callback_data: "help_guidelines"]
          ),
          inline_keyboard_button(
            "About",
            [callback_data: "help_about"]
          )
        ],
        [
          inline_keyboard_button(
            "Contact Us",
            [callback_data: "help_feedback"]
          )
        ]
      ]
    )
  end

  def build_location_button(user), do: build_location_button(user, "")
  def build_location_button(user, message_id) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "Home: " <> Template.get_location_desc_from_user(user, "home"),
            [callback_data: "edit_profile_locationtype_home"]
          )
        ],
        [
          inline_keyboard_button(
            "Work: " <> Template.get_location_desc_from_user(user, "work"),
            [callback_data: "edit_profile_locationtype_work"]
          )
        ],
        [
          inline_keyboard_button(
            "Live: " <> Template.get_location_desc_from_user(user, "live"),
            [callback_data: "edit_profile_locationtype_live"]
          )
        ],
        [
          inline_keyboard_button(
            "📔 Main Menu",
            [callback_data: "start_mainmenu" <> to_string(message_id)]
          )
        ]
      ]
    )
  end

  def build_location_specific_button(loc_type) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "Set #{loc_type}",
            [callback_data: "edit_profile_locationtype" <> String.downcase(loc_type)]
          )
        ]
      ]
    )
  end

  def build_current_location_button() do
    reply_keyboard_markup(
      [
        [
          keyboard_button(
            "Send Current Location",
            [request_location: true]
          )
        ]
      ], [one_time_keyboard: true, resize_keyboard: true]
    )
  end

  def build_latest_posts_inline_button(), do: build_latest_posts_inline_button("")
  def build_latest_posts_inline_button(message_id) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "Home",
            [switch_inline_query_current_chat: "home"]
          ),
          inline_keyboard_button(
            "Work",
            [switch_inline_query_current_chat: "work"]
          ),
          inline_keyboard_button(
            "Live",
            [switch_inline_query_current_chat: "live"]
          )
        ],
        [
          inline_keyboard_button(
            "📔 Main Menu",
            [callback_data: "start_mainmenu" <> to_string(message_id)]
          )
        ]
      ]
    )
  end

  def build_orb_notification_button(orb, user) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "🌐 Open on Web",
            [url: parse_inline_orb_profileurl(orb)]
          )
        ],
        [
          inline_keyboard_button(
            "💬 Chat",
            [url: parse_inline_orb_chaturl(orb, user)]
          )
        ]
      ]
    )
  end

  defp parse_inline_orb_profileurl(orb) do
    if String.contains?(PhosWeb.Endpoint.url, "localhost") do
      "web.scratchbac.com/"
    else
      "#{PhosWeb.Endpoint.url}/orb/#{orb.id}"
    end
  end

  defp parse_inline_orb_chaturl(%{initiator: initiator} = _orb, user) do
    if String.contains?(PhosWeb.Endpoint.url, "localhost") do
      "web.scratchbac.com/"
    else
      "#{PhosWeb.Endpoint.url}/memories/user/#{initiator.username}?token=#{Auth.generate_user!(user.id)}"
    end
  end

  def build_main_menu_inlinekeyboard(), do: build_main_menu_inlinekeyboard("")
  def build_main_menu_inlinekeyboard(message_id) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "📔 Main Menu",
            [callback_data: "start_mainmenu" <> to_string(message_id)]
          )
        ]
      ]
    )
  end

  def build_createorb_location_inlinekeyboard(user) do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "Home: " <> Template.get_location_desc_from_user(user, "home"),
            [callback_data: "createorb_location_home"]
          )
        ],
        [
          inline_keyboard_button(
            "Work: " <> Template.get_location_desc_from_user(user, "work"),
            [callback_data: "createorb_location_work"]
          )
        ],
        [
          inline_keyboard_button(
            "📍 Live Location",
            [callback_data: "createorb_location_live"]
          )
        ],
        [
          inline_keyboard_button(
            "📔 Main Menu",
            [callback_data: "start_mainmenu"]
          ),
          inline_keyboard_button(
            "↩️ Back",
            [callback_data: "createorb_back_description"]
          )
        ]
      ]
    )
  end

  def build_createorb_media_inlinekeyboard() do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "📔 Main Menu",
            [callback_data: "start_mainmenu"]
          ),
          inline_keyboard_button(
            "↩️ Back",
            [callback_data: "createorb_back_location"]
          )
        ],
        [
          inline_keyboard_button(
            "⏭️ Skip",
            [callback_data: "createorb_preview"]
          )
        ]
      ]
    )
  end

  def build_createorb_preview_inlinekeyboard() do
    inline_keyboard_markup(
      [
        [
          inline_keyboard_button(
            "📔 Main Menu",
            [callback_data: "start_mainmenu"]
          ),
          inline_keyboard_button(
            "↩️ Back",
            [callback_data: "createorb_back_media"]
          )
        ],
        [
          inline_keyboard_button(
            "✈️ Post",
            [callback_data: "createorb_post"]
          )
        ]
      ]
    )
  end

  def inline_keyboard_markup(buttons) do
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard: buttons}
  end
  def inline_keyboard_button(text) do
  end
  def inline_keyboard_button(text, opts) do
    callback_data = opts[:callback_data] || nil
    switch_inline_query_current_chat = opts[:switch_inline_query_current_chat] || nil
    url = opts[:url] || nil
    %ExGram.Model.InlineKeyboardButton{text: text, callback_data: callback_data, switch_inline_query_current_chat: switch_inline_query_current_chat, url: url}
  end

  def reply_keyboard_markup(buttons), do: reply_keyboard_markup(buttons, [])
  def reply_keyboard_markup(buttons, opts) do
    resize_keyboard = opts[:resize_keyboard] || false
    one_time_keyboard = opts[:one_time_keyboard] || false
    %ExGram.Model.ReplyKeyboardMarkup{one_time_keyboard: one_time_keyboard, resize_keyboard: resize_keyboard, keyboard: buttons}
  end
  def keyboard_button(text), do: keyboard_button(text, [])
  def keyboard_button(text, opts) do
    request_location = opts[:request_location] || false
    %ExGram.Model.KeyboardButton{text: text, request_location: request_location}
  end
end
