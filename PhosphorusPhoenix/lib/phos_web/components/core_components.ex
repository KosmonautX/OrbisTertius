defmodule PhosWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.

  Icons are provided by [heroicons](https://heroicons.com), using the
  [heroicons_elixir](https://github.com/mveytsman/heroicons_elixir) project.
  """
  use Phoenix.Component
  import Phoenix.VerifiedRoutes, warn: false
  import PhosWeb.SVG

  alias Phoenix.LiveView.JS
  import PhosWeb.Gettext
  import PhosWeb.Util.DOMParser

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{}, doc: "JS cancel action")
  attr(:on_confirm, JS, default: %JS{}, doc: "JS confirm action")
  attr(:background, :string, default: "bg-white")
  attr(:close_button, :boolean, default: true)
  attr(:main_width, :string, default: "w-full")

  slot(:inner_block, required: true)
  slot(:title)
  slot(:subtitle)

  slot(:confirm) do
    attr(:tone, :atom)
  end

  slot(:cancel)

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      class="relative z-50 hidden bg-white rounded-lg shadow dark:bg-gray-900 dark:lg:bg-gray-800 px-2 w-full mx-auto justify-center items-center"
    >
      <div
        id={"#{@id}-bg"}
        class={["fixed inset-0 bg-zinc-50/90 transition-opacity", @background]}
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto journal-scroll"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class={["max-w-3xl p-4 sm:p-6 lg:py-8", @main_width]}>
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="hidden relative rounded-2xl shadow-lg bg-white shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition dark:bg-gray-900 dark:lg:bg-gray-800"
            >
              <div :if={@close_button} class="absolute top-4 right-4">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-90 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <Heroicons.x_mark class="h-5 w-5 dark:text-white" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []} class="p-2 pb-3 border-b">
                  <h1
                    id={"#{@id}-title"}
                    class="text-lg font-semibold leading-8 text-zinc-800 dark:text-white"
                  >
                    <%= render_slot(@title) %>
                  </h1>
                  <p :if={@subtitle != []} class="text-sm leading-4 text-zinc-600 dark:text-gray-400">
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <div id={"#{@id}-main"} class="w-full">
                  <%= render_slot(@inner_block) %>
                </div>
                <div
                  :if={@confirm != [] or @cancel != []}
                  class="p-4 flex flex-row-reverse items-center gap-5"
                >
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    tone={Map.get(confirm, :tone, :primary)}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="py-2 px-3"
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
   Renders a user modal component.
    ## Examples
    <.user_modal/>
  """

  attr(:id, :string, required: true)

  def user_modal(assigns) do
    ~H"""
    <div
      id={@id}
      class="hidden w-44 list-none rounded-2xl bg-[#F3F4F8] py-2 text-base shadow-lg dark:bg-[#282828]"
    >
      <ul class="font-poppins font flex flex-col divide-y divide-gray-300 dark:divide-[#D1D1D1] text-base font-light text-[#404252] dark:text-[#D1D1D1]">
        <li class="px-4 py-2 hover:bg-gray-200 dark:hover:bg-gray-600 cursor-pointer">Share</li>
        <li class="px-4 py-2 hover:bg-gray-200 dark:hover:bg-gray-600 cursor-pointer">Block User</li>
        <li class="px-4 py-2 text-[#CE395F] hover:bg-gray-200 dark:text-[#EF426F] dark:hover:bg-gray-600 cursor-pointer">
          Report User
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, default: "flash", doc: "the optional id of flash container")

  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)

  attr(:kind, :atom,
    values: [:info, :error],
    doc: "used for styling and flash lookup"
  )

  attr(:autoshow, :boolean,
    default: true,
    doc: "whether to auto show the flash on mount"
  )

  attr(:close, :boolean, default: true, doc: "whether the flash can be closed")

  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  slot(:inner_block,
    doc: "the optional inner block that renders the flash message"
  )

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("#flash")}
      role="alert"
      class={[
        "absolute  hidden top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-lg shadow-zinc-900/5 ring-1 font-poppins",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 p-3 text-rose-900 shadow-lg ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-[0.8125rem] font-semibold leading-6">
        <Heroicons.information_circle :if={@kind == :info} mini class="h-4 w-4" />
        <Heroicons.exclamation_circle :if={@kind == :error} mini class="h-4 w-4" />
        <%= @title %>
      </p>
      <p :if={@title} class="mt-2 text-[0.8125rem] leading-5"><%= msg %></p>
      <p :if={is_nil(@title)} class="font-semibold text-[0.8125rem] leading-5"><%= msg %></p>
      <button
        :if={@close}
        type="button"
        class="group absolute top-2 right-1 p-2"
        aria-label={gettext("close")}
      >
        <Heroicons.x_mark solid class="h-5 w-5 stroke-current opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form :let={f} for={:user} phx-change="validate" phx-submit="save">
        <.input field={{f, :email}} label="Email"/>
        <.input field={{f, :username}} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>mounted
  """

  attr(:for, :any, default: nil, doc: "the datastructure for the form")

  attr(:as, :any,
    default: nil,
    doc: "the server side parameter to collect all input under"
  )

  attr(:color, :boolean, default: true)
  attr(:show_padding, :boolean, default: true)
  attr(:class, :string, default: nil, doc: "simple form class overide")

  attr(:rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"
  )

  slot(:inner_block, required: true)

  slot(:actions, doc: "the slot for form actions, such as a submit button") do
    attr(:classes, :string, doc: "simple form class overide")
  end

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class={[
        @color == false && "lg:dark:bg-gray-900 dark:bg-gray-800 bg-[#F3F4F8]",
        "bg-white font-poppins dark:bg-gray-900 lg:dark:bg-gray-800 w-full",
        @class
      ]}>
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class={"#{Map.get(action, :classes, "")}"}>
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button with predefined class

  This button have several themes such as: :primary, :success, :warning and :danger

  This button have several options such as
  - tone: tone of the button. can be :primary, :success, :warning or :danger. Default is: :primary
  - class: additional class if want to customize the button
  - type: button type. can be "button" or "submit". Default is "button"

  Rest of the options can be assigned in the element such as: disabled, name, value and phx-* binding

  ## Examples

      <.button tone={:primary}>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """

  attr(:tone, :atom,
    default: :primary,
    values: ~w(primary success warning danger dark icons)a,
    doc: "Theme of the button"
  )

  attr(:type, :string,
    default: "button",
    values: ~w(button submit reset),
    doc: "Type of button"
  )

  attr(:class, :string, default: "")

  attr(:rest, :global,
    include: ~w(disabled form name value),
    doc: "Rest of html attribute"
  )

  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        default_button_class(),
        button_class(@tone)
        | String.split(@class, " ")
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_class(:danger), do: "bg-red-400 hover:bg-red-600"

  defp button_class(:primary),
    do:
      "focus:outline-none focus:ring-4 font-bold rounded-full text-sm px-5 py-2.5 text-center bg-[#9747FF] text-[#D1D1D1] hover:bg-purple-700 focus:ring-purple-900 font-poppins"

  defp button_class(:warning), do: "bg-yellow-400 hover:bg-yellow-600"
  defp button_class(:success), do: "bg-green-400 hover:bg-green-600"
  defp button_class(:dark), do: "bg-slate-800 hover:bg-black text-white"

  defp button_class(:inlinebutton),
    do:
      "inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/30 dark:bg-gray-800/30 group-hover:bg-white/50 dark:group-hover:bg-gray-800/60 group-focus:ring-4 group-focus:ring-white dark:group-focus:ring-gray-800/70 group-focus:outline-none"

  defp button_class(:icons),
    do:
      "font-poppins inline-block text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 focus:ring-4 focus:outline-none focus:ring-gray-200 dark:focus:ring-gray-700 rounded-sm text-sm"

  defp default_button_class do
    [
      "phx-submit-loading:opacity-75",
      "rounded-lg",
      "font-poppins",
      "px-2",
      "py-2",
      "text-sm",
      "font-bold",
      "active:text-white/80"
    ]
    |> Enum.join(" ")
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={{f, :email}} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr(:id, :any)
  attr(:name, :any)
  attr(:label, :string, default: nil)

  attr(:type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)
  )

  attr(:value, :any)

  attr(:field, :any, doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :email}")

  attr(:errors, :list)
  attr(:checked, :boolean, doc: "the checked flag for checkbox inputs")
  attr(:prompt, :string, default: nil, doc: "the prompt for select inputs")

  attr(:options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2")

  attr(:multiple, :boolean,
    default: false,
    doc: "the multiple flag for select inputs"
  )

  attr(:rest, :global,
    include: ~w(hide_error autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step)
  )

  slot(:inner_block)

  def input(%{field: {f, field}} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn ->
      name = Phoenix.HTML.Form.input_name(f, field)
      if assigns.multiple, do: name <> "[]", else: name
    end)
    |> assign_new(:id, fn -> Phoenix.HTML.Form.input_id(f, field) end)
    |> assign_new(:value, fn -> Phoenix.HTML.Form.input_value(f, field) end)
    |> assign_new(:errors, fn -> translate_errors(f.errors || [], field) end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        input_equals?(assigns.value, "true")
      end)

    ~H"""
    <label phx-feedback-for={@name} class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        id={@id || @name}
        name={@name}
        value="true"
        checked={@checked}
        class="font-poppins rounded text-purple-600 bg-gray-100 border-gray-300 rounded focus:ring-purple-500 focus:ring-purple-900 dark:focus:ring-purple-600 dark:ring-offset-gray-800 dark:focus:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
        {@rest}
      />
      <%= @label %>
    </label>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="font-poppins mt-2 block w-full py-2 px-3 border bg-white rounded-lg shadow-sm focus:outline-none focus:ring-zinc-500 focus:border-zinc-500 sm:text-sm border-zinc-300 dark:bg-gray-600 dark:border-gray-500 dark:text-white"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt}><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea", rest: %{class: _class, hide_error: true}} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={[@rest.class]}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        rows="1"
        id={@id || @name}
        name={@name}
        class={[
          input_border(@errors),
          "peer block w-full border-0 appearance-none bg-transparent px-0 py-2.5 text-sm text-gray-900 focus:outline-none focus:ring-0 dark:text-white"
        ]}
        {@rest}
      >
    <%= @value %></textarea>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={@value}
        class={[
          input_border(@errors),
          "block w-full rounded-lg  border-zinc-300 dark:bg-gray-600 dark:border-gray-500  dark:placeholder-gray-400 dark:text-white font-poppins",
          "text-zinc-900 focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  defp input_border([] = _errors),
    do: "border-zinc-300 focus:border-zinc-400 focus:ring-zinc-800/5"

  defp input_border([_ | _] = _errors),
    do: "placeholder-rose-300 border-rose-400 focus:border-rose-400 focus:ring-rose-400/10"

  @doc """
  Renders a label.
  """
  attr(:for, :string, default: nil)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label
      for={@for}
      class="block text-sm font-semibold leading-6 text-zinc-800 dark:text-white font-poppins "
    >
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <p class="phx-no-feedback:hidden mt-3 flex gap-3 text-sm leading-6 text-rose-600 font-poppins">
      <Heroicons.exclamation_circle mini class="mt-0.5 h-5 w-5 flex-none fill-rose-500" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)
  slot(:subtitle)
  slot(:actions)

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6 font-poppins", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 dark:text-white">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="leading-6 dark:text-gray-400">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <:col :let={orb} label="Source"><%= @orb.|> get_in([
        :users_initiator, Access.key(%{}),
        :public_profile, Access.key(:birthday, "-")]) %></:col>

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """

  attr(:id, :string, required: true)
  attr(:row_click, :any, default: nil)
  attr(:rows, :list, required: true)
  attr(:row_class, :string, default: nil)

  slot :col, required: true do
    attr(:classes, :string, doc: "simple form class overide")
    attr(:label, :string)
  end

  slot(:action,
    doc: "the slot for showing user actions in the last table column"
  )

  def table(assigns) do
    ~H"""
    <div id={@id} class="relative w-full flex flex-col bg-white p-2  font-poppins">
      <table class="w-full align-top text-slate-500">
        <thead class=" py-3 font-bold text-left uppercase align-middle bg-transparent border-b border-gray-200 shadow-none text-base tracking-none whitespace-nowrap text-slate-400">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 "><%= col[:label] %></th>
            <th class="relative p-0 pb-4">
              <span class="sr-only"><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody class="align-top text-sm">
          <tr
            :for={row <- @rows}
            id={"#{@id}-#{Phoenix.Param.to_param(row)}"}
            class={[
              "relative group hover:bg-gray-100 dark:bg-gray-800 dark:text-white ",
              @row_class
            ]}
          >
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={[
                "px-2",
                @row_click && "hover:cursor-pointer",
                "#{Map.get(col, :classes, "")}"
              ]}
            >
              <div :if={i == 0}>
                <span class="absolute h-full group-hover:bg-zinc-50 " />
              </div>
              <div class="block py-2">
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, row) %>
                </span>
              </div>
            </td>

            <td :if={@action != []} class="p-0 ">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, row) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a Admin User Preview of Email & Username.
  """

  attr(:user, :map, required: true)
  attr(:id, :string, required: true)

  def admin_user_preview(assigns) do
    ~H"""
    <div class="flex items-center space-x-4">
      <div class="flex-shrink-0">
        <.link navigate={"/user/#{@user.username}?bac"}>
          <img
            class="lg:w-12 lg:h-12 h-10 w-10 rounded-full object-cover"
            src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossy")}
            onerror="this.src='/images/default_banner.jpg';"
          />
        </.link>
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-gray-900 truncate">
          <%= "#{@user.username}" %>
        </p>
        <p href={"mailto: #{@user.email}"} class="lg:text-sm text-xs text-gray-500 truncate">
          <%= "#{@user.email}" %>
        </p>
      </div>
    </div>
    """
  end

  attr(:user, :map, required: true)
  attr(:orb, :map, required: true)
  attr(:id, :string, required: true)

  @doc """
  Render a Admin Grid Using in Mobile Responsive Admin Dashboard

  ## Examples
  <.admin_grid user={orb.initiator}></.admin_grid>
  """

  @spec admin_grid(map) :: Phoenix.LiveView.Rendered.t()
  def admin_grid(assigns) do
    ~H"""
    <div class="w-full bg-gray-50 rounded-2xl flex flex-col items-center py-2 font-poppins justify-center">
      <img
        class="md:w-24 md:h-24 h-20 w-20 rounded-full shadow-lg object-cover img-double-border"
        src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossless")}
        alt=""
        onerror="this.src='/images/default_hand.jpg';"
      />
      <h5 class="text-lg md:text-xl font-bold tracking-tight text-gray-900">
        <%= "#{@user.username}" %>
      </h5>

      <p class="text-gray-400 font-semibold flex gap-1">
        <span class="flex text-sm">
          <Heroicons.user class="w-4 h-4 mr-2" /> USER NAME
        </span>
        <span class="font-bold text-xs  text-gray-600 text-base -mt-1">
          <%= @user |> get_in([Access.key(:public_profile, %{}), Access.key(:public_name, "")]) %>
        </span>
      </p>

      <p class="text-gray-400 font-semibold  flex gap-1">
        <span class="flex text-sm">
          <Heroicons.calendar class="w-4 h-4 mr-2" /> REVIEW DATE
        </span>
        <span class="font-bold text-gray-600 text-base text-xs -mt-1">
          <%= @user |> get_in([Access.key(:public_profile, %{}), Access.key(:birthday, "")]) %>
        </span>
      </p>

      <p class="text-gray-400 font-semibold flex gap-1">
        <span class="flex text-sm">
          <Heroicons.adjustments_horizontal class="w-4 h-4 mr-2" />TAGS
        </span>
        <span
          :for={
            trait <-
              @user |> get_in([Access.key(:public_profile, %{}), Access.key(:traits, nil)]) || []
          }
          class="text-xs font-bold text-gray-600 text-base -mt-1"
        >
          <%= "#{trait}" %>
        </span>
      </p>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """

  attr(:type, :string,
    default: "normal",
    values: ["normal", "stripped"],
    doc: "List type"
  )

  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14 mb-6 font-poppins">
      <dl
        class={"-my-4 divide-y divide-zinc-100 #{if(@type == "stripped", do: "[&>*:nth-child(odd)]:bg-gray-200 border border-gray-200 rounded-lg")}"}
        ]
      >
        <div :for={item <- @item} class="flex gap-4 py-4 sm:gap-8 rounded-lg">
          <dt class="pl-2 w-1/4 flex-none text-[0.8125rem] leading-6 text-zinc-500">
            <%= item.title %>
          </dt>
          <dd class="text-sm leading-6 text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr(:navigate, :any, required: true)
  slot(:inner_block, required: true)

  def back(assigns) do
    ~H"""
    <div class="mt-16 font-poppins">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <Heroicons.arrow_left solid class="w-3 h-3 stroke-current inline" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a card component.

  ## Examples
      <.card title="Card title">
        Body
      </.card>
  """
  attr(:title, :string, required: true)
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)
  slot(:actions, doc: "the slot for form actions, such as a submit button")

  attr(:rest, :global,
    include: ~w(id name rel),
    doc: "the arbitrary HTML attributes to apply to the form tag"
  )

  def card(assigns) do
    ~H"""
    <div class={["flex flex-col min-w-0 break-words w-full mb-6 ", @class]} {@rest}>
      <div class="rounded-t mb-0 px-4 border-0 font-poppins">
        <h1 class="font-semibold text-lg text-gray-700"><%= @title %></h1>
      </div>
      <div class="block w-full px-2">
        <%= render_slot(@inner_block) %>
      </div>
      <div :for={action <- @actions} class="px-2 mt-2 mb-4 flex items-center justify-between gap-6">
        <%= render_slot(action) %>
      </div>
    </div>
    """
  end

  @doc """
    Render a Admin Navbar is help to Navigate a new Route

  ## Examples
      <.admin_navbar title="ScratchBac Admin" home_path={~p"/admin"}>
      <:item to={~p"/admin/dashboard"} title="Dashboard" id="dashboard" icon="fa-tv" />
      <:item to={~p"/admin/orbs"} title="Orbs" id="orb" icon="fa-dharmachakra"/>
      <:item to={~p"/admin/notifications"} title="Notifications" id="notification" icon="fa-clock" />
      </.admin_navbar>
  """

  attr(:title, :string, required: true)
  attr(:home_path, :string, required: true)

  slot :item,
    required: true,
    doc: "the slot for form actions, such as a submit button" do
    attr(:to, :string, required: true)
    attr(:title, :string, required: true)
    attr(:icon, :string, required: true)
    attr(:id, :string)
    attr(:name, :string)
  end

  def admin_navbar(assigns) do
    ~H"""
    <nav class="lg:bg-gray-50 bg-white flex px-4 font-poppins py-4 w-64 h-screen border border-gray-100">
      <ul class="flex-col min-w-full flex flex-col list-none" id="navbar">
        <li :for={item <- @item} class="items-center">
          <.link
            navigate={item.to}
            class="text-sm uppercase py-3 font-bold block text-gray-500 hover:text-teal-400"
          >
            <i class={"fas mr-2 text-sm opacity-75 #{item.icon}"}></i>
            <%= item.title %>
          </.link>
        </li>
      </ul>
    </nav>
    """
  end

  @doc """
  Render a Admin banner is using Menu button in mobile responsive
  """

  @spec nav_banner_admin(any) :: Phoenix.LiveView.Rendered.t()
  def nav_banner_admin(assigns) do
    ~H"""
    <nav class="bg-white fixed w-full z-10 top-0 left-0 border-b border-gray-200 text-base font-bold p-3 font-poppins">
      <div class=" flex flex-wrap items-center justify-between mx-auto">
        <a href="" class="flex items-center">
          <.logo type="banner" class="h-8 ml-4"></.logo>
        </a>
        <button
          type="button"
          phx-click={JS.toggle(to: "#nav-form")}
          class="lg:hidden block items-center text-sm text-gray-500 rounded-lg"
        >
          <Heroicons.bars_3 class="w-6 h-6 text-gray-700 hover:text-teal-500" />
        </button>
      </div>
    </nav>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(PhosWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PhosWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """

  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  defp input_equals?(val1, val2) do
    Phoenix.HTML.html_escape(val1) == Phoenix.HTML.html_escape(val2)
  end

  @doc """
  Render the Banner its working only for current_user
  Banner is main of the website its help route in particular

  ## Example

    <%= if @current_user do %>
      <.banner :if={@current_user} current_user={@current_user} />
    <% else %>
  """

  attr(:current_user, :map, required: true)

  def banner(assigns) do
    ~H"""
    <nav class="lg:bg-[#EEEFF3] bg-white fixed w-full z-10 top-0 left-0 border-b dark:text-white lg:border-none text-base font-bold dark:bg-gray-900 px-4 lg:py-3 py-2 font-poppins border-gray-300">
      <div class="flex flex-wrap items-center justify-between mx-auto">
        <a href="/" class="flex items-center">
          <.logo type="banner" class="h-8 dark:fill-white"></.logo>
        </a>
        <div class="flex items-center lg:order-2 flex-col lg:flex-row lg:space-x-2 lg:w-auto">
          <ul class="flex flex-wrap text-center text-gray-700">
            <li :if={not is_nil(@current_user.username)} class="mr-2 hidden lg:block">
              <span class="rounded-t-lg hover:text-teal-500 group">
                <.link navigate={
                  path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@current_user.username}")
                }>
                  <Heroicons.user_circle
                    mini
                    class="w-8 h-8 text-gray-700 group-hover:text-teal-500  dark:text-white"
                  />
                </.link>
              </span>
            </li>

            <li class="mr-2 hidden lg:block">
              <span class="rounded-t-lg hover:text-teal-500 group">
                <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/users/settings")}>
                  <Heroicons.cog_8_tooth
                    mini
                    class="w-8 h-8 text-gray-700 group-hover:text-teal-500  dark:text-white"
                  />
                </.link>
              </span>
            </li>

            <li class="mr-2 hidden lg:block">
              <span class=" rounded-t-lg hover:text-teal-500 group">
                <.link
                  href={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/users/log_out")}
                  method="delete"
                >
                  <Heroicons.arrow_left_on_rectangle
                    mini
                    class="w-8 h-8 text-gray-700 group-hover:text-teal-500  dark:text-white"
                  />
                </.link>
              </span>
            </li>
          </ul>
          <div class="flex gap-2">
            <button
              class="text-[#EEEFF3] bg-[#000000] hover:bg-gray-400 focus:outline-none focus:ring-4 focus:ring-gray-300 font-bold rounded-full text-sm px-5 py-2.5 text-center dark:bg-[#9747FF] dark:text-[#D1D1D1] dark:hover:bg-purple-700 dark:focus:ring-purple-900 font-poppins"
              type="button"
              id="welcome-button"
              phx-click={show_modal("welcome_message")}
            >
              Open app
            </button>
            <button
              id="theme-toggle"
              type="button"
              class="text-gray-700 dark:text-white rounded-sm text-sm p-1"
            >
              <Heroicons.moon
                mini
                id="theme-toggle-dark-icon"
                class="hidden w-6 h-6 text-gray-700 group-hover:text-teal-500 dark:text-white"
              />
              <Heroicons.sun
                mini
                id="theme-toggle-light-icon"
                class="hidden w-6 h-6 text-gray-700 group-hover:text-teal-500 dark:text-white"
              />
            </button>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  @doc """
  Render the Guest_banner is using welcome the user

  ## Using Js in show modal
    <.button type="button" phx-click={show_modal("welcome_message")}>
    Open app
    </.button>

  ## Example
      <.guest_banner if={is_nil(@current_user)} current_user={@current_user} />
  """

  def guest_banner(assigns) do
    ~H"""
    <nav class="bg-white fixed w-full z-10 top-0 left-0 text-base font-bold dark:bg-gray-900 px-4 py-3 font-poppins border-gray-200">
      <div class="flex flex-wrap items-center justify-between mx-auto">
        <a href="//www.scratchbac.com/blog" class="flex items-center">
          <.logo type="banner" class="h-8 dark:fill-white"></.logo>
        </a>
        <div class="flex gap-2">
          <button
            id="welcome-button"
            type="button"
            phx-click={show_modal("welcome_message")}
            class="text-[#EEEFF3] bg-[#000000] hover:bg-gray-400 focus:outline-none focus:ring-4 focus:ring-gray-300 font-bold rounded-full text-sm px-5 py-2.5 text-center dark:bg-[#9747FF] dark:text-[#D1D1D1] dark:hover:bg-purple-700 dark:focus:ring-purple-900 font-poppins"
          >
            Open app
          </button>
          <button
            id="theme-toggle"
            type="button"
            class="text-gray-700 dark:text-white rounded-sm text-sm p-1"
          >
            <Heroicons.moon
              mini
              id="theme-toggle-dark-icon"
              class="hidden w-6 h-6 text-gray-700 group-hover:text-teal-500 dark:text-white"
            />
            <Heroicons.sun
              mini
              id="theme-toggle-light-icon"
              class="hidden w-6 h-6 text-gray-700 group-hover:text-teal-500 dark:text-white"
            />
          </button>
        </div>
      </div>
    </nav>
    """
  end

  @doc """
  Render the  tabs_profile its help to mobile responsive tabs in profile view
  """

  attr(:title, :string, required: true)
  attr(:home_path, :string, required: true)
  slot(:information)

  slot :item,
    required: true,
    doc: "the slot for form actions, such as a submit button" do
    attr(:to, :string, required: true)
    attr(:title, :string, required: true)
    attr(:icon, :string, required: true)
    attr(:id, :string)
    attr(:name, :string)
  end

  def tabs_mobile_view(assigns) do
    ~H"""
    <div class="mx-auto w-full lg:hidden block dark:bg-gray-900">
      <div class="absolute inset-x-2 py-2 flex items-center justify-end px-2 md:px-10">
        <%= render_slot(@information) %>
      </div>
      <div class="flex py-2">
        <div class="flex flex-1 items-center justify-center">
          <ul class="flex flex-wrap justify-center items-center md:gap-10 gap-2">
            <li :for={item <- @item}>
              <.link
                navigate={item.to}
                class="text-sm uppercase font-bold block hover:text-[[#777986]] dark:text-[#D1D1D1]"
              >
                <i class={"fas mr-2 text-sm opacity-75 #{item.icon}"}></i>
                <%= item.title %>
              </.link>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Render the user info bar is collect the user details

  ##Example
      <.user_info_bar >

      #### slot
        <:information :if={!is_nil(@orb_location)}>
            <.location type="button" class="h-8 dark:fill-white"></.location>
        </:information>

      ####  Action Button
        <:actions>
          <.chat type="banner" class="h-8 ml-4 dark:fill-white"></.chat>
        </:actions>
      </.user_info_bar>
  """
  attr(:class, :string, default: nil)
  attr(:id, :string, required: true)
  attr(:show_padding, :boolean, default: true)
  attr(:profile_img, :boolean, default: true)
  attr(:profile_border, :boolean, default: true)
  attr(:show_user, :boolean, default: true)
  attr(:color, :boolean, default: true)
  attr(:orb_color, :boolean, default: true)
  attr(:show_location, :boolean, default: true)
  attr(:user, :any)
  slot(:actions)
  slot(:information)

  def user_info_bar(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        @show_padding == false && "lg:px-4",
        @orb_color == true && "dark:bg-gray-800 bg-[#F3F4F8]",
        @color == true && "lg:dark:bg-gray-800",
        "lg:dark:bg-gray-900 dark:bg-gray-900 lg:bg-white w-full lg:py-2 py-3 flex items-center justify-between px-2 font-poppins",
        @class
      ]}
    >
      <div class="flex">
        <.link
          :if={@user.username}
          navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}")}
          class="flex shrink-0"
        >
          <img
            src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossy")}
            class={[
              @profile_img == false && "lg:w-10 lg:h-10",
              @profile_border == true && "border-red-400 border-4",
              "h-12 w-12 rounded-full object-cover border-none border-red-900"
            ]}
            onerror="this.src='/images/default_hand.jpg';"
          />
        </.link>
        <div class="flex flex-col justify-center ml-1.5">
          <.link
            :if={@user.username}
            navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}")}
          >
            <p class={[
              @show_user == false && "lg:text-base",
              "font-bold text-gray-900 dark:text-white text-sm"
            ]}>
              <%= "@#{@user.username}" %>
            </p>
          </.link>
          <p class={[
            @show_location == false && "lg:text-sm text-[#000000] dark:text-white",
            @show_location == true && "lg:text-xs dark:text-[#00D2C4] text-[#00BFB2]",
            "flex items-center text-sm font-light"
          ]}>
            <%= render_slot(@information) %>
          </p>
        </div>
      </div>
      <div class="flex gap-2 cursor-pointer"><%= render_slot(@actions) %></div>
    </div>
    """
  end

  @doc """
   Orb Card View  with user info bar
  """
  attr(:id, :string, required: true)
  attr(:orb, :map)
  attr(:timezone, :map)
  slot(:user_action)
  attr(:show_information, :boolean, default: true)
  attr(:show_info, :boolean, default: true)
  attr(:show_padding, :boolean, default: true)
  attr(:profile_img, :boolean, default: true)
  attr(:show_user, :boolean, default: true)
  attr(:show_location, :boolean, default: true)
  attr(:orb_color, :boolean, default: true)
  attr(:color, :boolean, default: true)
  attr(:class, :string, default: nil)

  def scry_orb(assigns) do
    assigns =
      assigns
      |> assign(
        :orb_location,
        assigns.orb
        |> get_in([Access.key(:payload, %{}), Access.key(:where, "-")]) ||
          assigns.orb.central_geohash |> Phos.Mainland.World.locate() ||
          "Somewhere"
      )
      |> assign(
        :media,
        Phos.Orbject.S3.get_all!("ORB", assigns.orb.id, "public/banner")
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
      )

    ~H"""
    <div class="w-full lg:px-0 px-3 relative">
      <div class="absolute right-0 z-10 mr-4 lg:mt-10 mt-12">
        <.user_modal id={"#{@id}-orb-modal-#{@orb.id}"} />
      </div>

      <.user_info_bar
        class="rounded-t-3xl"
        id={"#{@id}-scry-orb-#{@orb.id}"}
        user={@orb.initiator}
        show_padding={@show_padding}
        profile_img={@profile_img}
        show_user={@show_user}
        show_location={@show_location}
        color={@color}
        orb_color={@orb_color}
      >
        <:information :if={!is_nil(@orb_location)}>
          <span class="mr-1">
            <.location type="location" class="h-8 dark:fill-teal-600"></.location>
          </span>
          <%= @orb_location %>
        </:information>
        <:actions>
          <Heroicons.ellipsis_horizontal
            phx-click={JS.toggle(to: "##{@id}-orb-modal-#{@orb.id}")}
            class="lg:h-8 lg:w-8 h-6 w-6 hover:text-gray-300 dark:text-white text-gray-900 font-semibold"
          />
          <%= render_slot(@user_action) %>
        </:actions>
      </.user_info_bar>

      <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}")}>
        <.orb_information
          id={"#{@id}-orb-info-#{@orb.id}"}
          color={@color}
          show_padding={@show_padding}
          show_info={@show_info}
          orb_color={@orb_color}
          title={(@orb.payload && @orb.payload.inner_title) || @orb.title}
        />
        <.orb_information
          :if={
            is_binary(get_in(@orb, [Access.key(:payload), Access.key(:info)])) && !@show_information
          }
          id={"#{@id}-scry-orb-#{@orb.id}"}
          title={@orb.payload.info}
          show_link={true}
          show_padding={@show_padding}
          show_info={@show_info}
          orb_color={@orb_color}
          color={@color}
        />
      </.link>

      <.media_carousel
        :if={@media != []}
        archetype="ORB"
        uuid={@orb.id}
        path="public/banner"
        id={"#{@id}-scry-orb-#{@orb.id}"}
        orb={@orb}
        orb_color={@orb_color}
        timezone={@timezone}
        media={@media}
        color={@color}
      />

      <.orb_action
        id={"#{@id}-scry-orb-#{@orb.id}"}
        orb={@orb}
        date={@timezone}
        color={@color}
        show_info={@show_info}
        show_padding={@show_padding}
        orb_color={@orb_color}
        show_information={@show_information}
      />
    </div>
    """
  end

  @spec media_carousel(map) :: Phoenix.LiveView.Rendered.t()
  @doc """
   User Post Image and video using js in carousel

  """
  attr(:id, :string, required: true)
  attr(:archetype, :string, required: true)
  attr(:uuid, :string, required: true)
  attr(:path, :string)
  attr(:orb, :any)
  attr(:timezone, :string)
  attr(:show_comment, :boolean, default: true)
  attr(:color, :boolean, default: true)
  attr(:orb_color, :boolean, default: true)
  attr(:show_media, :boolean, default: true)

  attr(:img_size, :string,
    default: "h-96 lg:rounded-none rounded-[25px] px-2 lg:px-0 object-cover"
  )

  attr(:video_size, :string,
    default: "h-96 lg:rounded-none rounded-[25px] px-2 lg:px-0 object-cover"
  )

  attr(:media, :any)

  def media_carousel(assigns) do
    ~H"""
    <div :if={!is_nil(@media)} id={"#{@id}-carousel-wrapper"} class="glide">
      <section
        class="relative flex flex-col w-full font-poppins"
        id={"#{@id}-carousel"}
        phx-update="ignore"
        phx-hook="Carousel"
      >
        <div id={"#{@id}-container"} data-glide-el="track" class="glide__track w-full">
          <div class="glide__slides">
            <div :for={m <- @media} class="glide__slide">
              <div class={[
                @orb_color == true && "dark:bg-gray-800 bg-[#F3F4F8]",
                @color == true && "lg:dark:bg-gray-800",
                "lg:dark:bg-gray-900 dark:bg-gray-900 lg:bg-white relative"
              ]}>
                <.link
                  class="relative"
                  navigate={
                    unverified_path(
                      PhosWeb.Endpoint,
                      PhosWeb.Router,
                      "/orb/#{@orb.id}?media=#{m.path}"
                    )
                  }
                >
                  <img
                    :if={(m.ext |> String.split("/") |> hd) in ["image", "application"]}
                    class={[@img_size, "cursor-pointer w-full py-1"]}
                    src={m.url}
                    loading="lazy"
                  />
                </.link>
                <video
                  :if={(m.ext |> String.split("/") |> hd) in ["video"]}
                  class={[@video_size, "w-full aspect-video py-1"]}
                  muted
                  loop
                  preload="metadata"
                  playsinline
                >
                  <source src={m.url<> "#t=0.1"} type={m.ext} />
                </video>
                <a
                  :if={(m.ext |> String.split("/") |> hd) in ["video"]}
                  class="absolute hover:text-blue-300 inset-0 bg-transparent flex justify-center items-center p-2 hover:cursor-pointer"
                  data-selector="mute"
                  onclick="
                    this.previousElementSibling.muted = !this.previousElementSibling.muted;
                    this.firstElementChild.firstElementChild.classList.toggle('hidden')
                    this.firstElementChild.lastElementChild.classList.toggle('hidden')"
                >
                  <span class="h-10 w-10 items-center justify-center rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none hidden">
                    <Heroicons.speaker_x_mark class="h-6 w-6 hover:text-blue-300 text-white font-semibold" />
                    <Heroicons.speaker_wave class="hidden h-6 w-6 hover:text-blue-300 text-white font-semibold" />
                  </span>
                </a>
              </div>
            </div>
          </div>
        </div>

        <div :if={length(@media) > 1} data-glide-el="controls" class="h-full">
          <button
            id={"#{@id}-carousel-prev"}
            type="button"
            data-glide-dir="<"
            class="hidden lg:block absolute inset-y-2/4	 left-0  flex items-center justify-center  px-2 cursor-pointer group focus:outline-none"
          >
            <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
              <Heroicons.chevron_left class="mt-0.5 h-6 w-6" />
            </span>
          </button>
          <button
            id={"#{@id}-carousel-next"}
            type="button"
            data-glide-dir=">"
            class="hidden lg:block absolute inset-y-2/4	 right-0 flex items-center justify-center px-2 cursor-pointer group focus:outline-none"
          >
            <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
              <Heroicons.chevron_right class="mt-0.5 h-6 w-6" />
            </span>
          </button>

          <div
            data-glide-el="controls[nav]"
            class="absolute flex space-x-2 -translate-x-1/2 -bottom-4 left-1/2"
          >
            <button
              :for={count <- Enum.to_list(1..length(@media))}
              class="h-1.5 w-1.5 rounded-full bg-black/70 group-hover:bg-black-50 dark:bg-white/70 dark:group-hover:bg-white/90 group-hover:bg-black/90 focus:ring-4 dark:focus:ring-white focus:ring-black/20 group-focus:outline-none"
              data-glide-dir={"=#{count}"}
            />
          </div>
        </div>
      </section>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:url, :string, default: "")
  attr(:orb, :map)
  attr(:timezone, :map)
  slot(:user_action)

  def media_preview(assigns) do
    assigns =
      assigns
      |> assign(
        :orb_location,
        assigns.orb
        |> get_in([Access.key(:payload, %{}), Access.key(:where, "-")]) ||
          assigns.orb.central_geohash |> Phos.Mainland.World.locate() ||
          "Somewhere"
      )
      |> assign(
        :media,
        Phos.Orbject.S3.get_all!("ORB", assigns.orb.id, "public/banner")
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
      )

    ~H"""
    <div class="w-full mx-auto dark:bg-gray-900 dark:lg:bg-gray-800 bg-white flex h-screen w-full flex-col">
      <div class="px-2 md:px-6 lg:px-2 flex w-full items-center gap-4">
        <.user_info_bar
          class="dark:bg-gray-900"
          id={"#{@id}-scry-orb-#{@orb.id}"}
          user={@orb.initiator}
          profile_img={false}
          show_padding={true}
          orb_color={false}
          color={true}
        >
          <:information :if={!is_nil(@orb_location)}>
            <span class="mr-1">
              <.location type="location" class="h-8 dark:fill-teal-600"></.location>
            </span>
            <%= @orb_location %>
          </:information>
          <:actions>
            <Heroicons.ellipsis_horizontal class="lg:h-8 lg:w-8 h-6 w-6 hover:text-gray-300 dark:text-white text-gray-900 font-semibold" />
            <%= render_slot(@user_action) %>
          </:actions>
        </.user_info_bar>
      </div>

      <div class="flex flex-1 items-center justify-center">
        <.preview_modal :if={@media != []} id={"#{@id}-scry-orb-#{@orb.id}"} media={@media} />
      </div>

      <div class="w-full space-y-1 px-2 md:px-6 lg:px-4 bg-white dark:bg-gray-900 dark:lg:bg-gray-800 mb-10 lg:mb-24">
        <.orb_information
          id={"#{@id}-orb-info-#{@orb.id}"}
          color={true}
          orb_color={false}
          title={(@orb.payload && @orb.payload.inner_title) || @orb.title}
        />
        <.orb_action
          id={"#{@id}-scry-orb-#{@orb.id}"}
          orb={@orb}
          color={true}
          date={@timezone}
          orb_color={false}
          show_comment={false}
        />
        <p class="font-medium text-sm dark:text-white text-gray-700 px-2 py-1">
          Liked by bbeebbub and others
        </p>
        <hr />
        <span class="dark:text-white text-gray-400 font-normal text-sm lg:text-base mt-2 mb-2 px-2">
          23 comments
        </span>
        <hr />
      </div>
    </div>
    """
  end

  attr(:media, :any)
  attr(:id, :string, required: true)

  def preview_modal(assigns) do
    ~H"""
    <div
      class="relative flex items-center dark:bg-gray-900 dark:lg:bg-gray-800 bg-white"
      id={"#{@id}-carousel"}
    >
      <div :if={!is_nil(@media)}>
        <div :for={m <- @media} class="relative">
          <img
            class="max-h-full max-w-full object-contain flex justify-center items-center"
            src={m.url}
            loading="lazy"
          />
        </div>
      </div>
      <div :if={length(@media) > 1}>
        <button
          type="button"
          class="absolute inset-y-2/4	 right-0  flex items-center justify-center px-2 cursor-pointer group focus:outline-none"
        >
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none dark:group-focus:ring-gray-800/70 dark:bg-gray-800/30 dark:group-hover:bg-gray-800/60">
            <Heroicons.chevron_right class="h-6 w-6 dark:text-white" />
          </span>
        </button>
        <button
          type="button"
          class="absolute inset-y-2/4	 left-0  flex items-center justify-center px-2 cursor-pointer group focus:outline-none"
        >
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none dark:group-focus:ring-gray-800/70 dark:bg-gray-800/30 dark:group-hover:bg-gray-800/60">
            <Heroicons.chevron_left class="h-6 w-6 dark:text-white" />
          </span>
        </button>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, default: "")
  attr(:class, :string, default: nil)
  attr(:username, :string)
  attr(:color, :boolean, default: true)
  attr(:show_padding, :boolean, default: true)
  attr(:show_info, :boolean, default: true)
  attr(:orb_color, :boolean, default: true)

  attr(:info_color, :string,
    default:
      "prose-zinc text-gray-600 w-full bg-white lg:dark:bg-gray-900  dark:bg-gray-900 prose-a:text-teal-400 dark:prose-a:text-white prose-a:underline dark:prose-a:underline dark:decoration-white decoration-teal-500 decoration-2 text-sm"
  )

  attr(:show_link, :boolean, default: false)

  def orb_information(assigns) do
    # needs to be async and handled on client side scraping

    #   |> assign(:link,
    #   case PhosWeb.Util.DOMParser.extract_link_from_markdown(assigns.title) do
    #   "" -> nil
    #   link when is_binary(link) -> link
    #   _ -> nil
    # end)

    ~H"""
    <div class={[
      @class,
      @show_padding == false && "lg:px-4",
      @orb_color == true && "dark:bg-gray-800 bg-[#F3F4F8]",
      @color == true && "lg:dark:bg-gray-800",
      "px-2 font-poppins break-words lg:dark:bg-gray-900 dark:bg-gray-900 lg:bg-white",
      @info_color
    ]}>
      <span class={[
        @show_info == false && "lg:text-xs",
        "prose prose-a:text-blue-500 dark:prose-a:text-white text-sm break-words overflow-hidden font-medium dark:prose-invert w-full dark:text-white",
        @info_color
      ]}>
        <%= extract_html_from_md(@title) %>
      </span>
    </div>
    """
  end

  @doc """
   Render a External link is use to share hyperlinks
  """
  attr(:link, :string, default: nil)

  def external_orb_link(assigns) do
    assigns =
      assign(
        assigns,
        :page,
        case LinkPreview.create(assigns.link) do
          {:ok, page} -> page
          _ -> nil
        end
      )

    ~H"""
    <a
      :if={not is_nil(@page)}
      href={@link}
      class="w-full max-auto h-32 flex flex-row items-center rounded-xl hover:bg-gray-100 dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700 font-poppins bg-gray-50"
    >
      <img
        :if={@page.images != []}
        class="object-cover h-32 w-40 rounded-l-xl rounded-none"
        src={List.first(@page.images)[:url]}
      />
      <div class="flex flex-col justify-between text-left ml-2 mx-3 space-y-1 p-2">
        <h5 class="text-sm font-bold text-black dark:text-white break-words">
          <%= @page.title %>
        </h5>
        <p class="text-xs text-gray-700 dark:text-gray-400 break-words">
          <%= @page.description %>
        </p>
      </div>
    </a>
    """
  end

  attr(:orb, :any)

  def orb_link(assigns) do
    ~H"""
    <div
      href="#"
      class="w-full mx-auto rounded-xl py-1 hover:bg-gray-100 items-start relative w-full justify-between"
    >
      <div class="flex">
        <div class="flex-1 font-Poppins px-2 py-2 border-l-4 rounded-lg  border-black ml-2">
          <p class="text-xs font-bold text-black mb-1">
            You're Chatting about
          </p>
          <p class="text-xs font-normal text-gray-600 break-all">
            <%= @orb.title %>
          </p>
        </div>
        <img
          :if={@orb.media}
          class="h-20 w-20 rounded-lg object-cover p-1 mr-1"
          src={Map.values(Phos.Orbject.S3.get_all!("ORB", @orb.id, "public/banner/lossy"))}
        />
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:orb, :any)
  attr(:date, :string)
  attr(:class, :string, default: nil)
  attr(:show_comment, :boolean, default: true)
  attr(:show_information, :boolean, default: true)
  attr(:show_padding, :boolean, default: true)
  attr(:show_info, :boolean, default: true)
  attr(:color, :boolean, default: true)
  attr(:orb_color, :boolean, default: true)

  # TODO orb_actions wiring with data
  def orb_action(assigns) do
    ~H"""
    <div
      id={"#{@id}-actions"}
      class={[
        @show_padding == false && "lg:px-4",
        @orb_color == true && "dark:bg-gray-800 bg-[#F3F4F8]",
        @show_information == false && "lg:rounded-b-3xl",
        @color == true && "lg:dark:bg-gray-800",
        "lg:dark:bg-gray-900 rounded-none  dark:bg-gray-900 lg:bg-white w-full px-2 p-1 lg:mt-0 font-poppins",
        @class
      ]}
    >
      <span class={[@show_info == false && "lg:text-xs", "dark:text-white text-black text-sm"]}>
        <%= get_date(@orb.inserted_at, @date) %>
      </span>
      <div id={"#{@id}-actions-bar"} class="flex justify-between items-center mb-1">
        <div class="flex">
          <button class="text-center inline-flex items-center ">
            <.save
              type="save"
              class={[@show_info == false && "lg:h-4 lg:w-4", "dark:fill-white w-5 h-5"]}
            />
          </button>
        </div>
        <div class="flex flex-cols gap-2">
          <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}")}>
            <button class="text-center inline-flex items-center">
              <.comment
                type="comment"
                class={[@show_info == false && "lg:h-4 lg:w-4", "dark:fill-white w-5 h-5"]}
              />
              <span class={[
                @show_info == false && "lg:text-sm",
                "ml-1 dark:text-white text-base font-poppins"
              ]}>
                <%= @orb.comment_count %>
              </span>
            </button>
          </.link>
          <button
            id={"#{@id}-scry-orb-#{@orb.id}-sharebtn"}
            phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-scry-orb-#{@orb.id}-copylink")}
            class="text-center inline-flex items-center"
          >
            <div id={"#{@id}-scry-orb-#{@orb.id}-copylink"} class="hidden">
              <%= PhosWeb.Endpoint.url() <>
                path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}") %>
            </div>
            <.share
              type="share"
              class={[@show_info == false && "lg:h-4 lg:w-4", "dark:fill-white w-5 h-5 -mt-1.5"]}
            />
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:img_path, :string)
  slot(:user_name)
  attr(:user, :any)
  attr(:orb, :any)

  def redirect_mobile(assigns) do
    ~H"""
    <div
      data-selector="phos_modal_message"
      class="relative bg-white max-w-sm lg:max-w-lg lg:h-auto rounded-xl shadow-lg font-poppins "
    >
      <div class="flex flex-col justify-center items-center p-6 space-y-2 ">
        <img
          src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
          class="h-16 w-16 lg:w-32 lg:h-32 border-4 border-white rounded-full object-cover"
        />
        <h1 class="text-lg font-bold">Hmm...You were saying?</h1>
        <h3 class="text-base font-normal text-gray-500 text-center">
          Join the tribe to share your thoughts with raizzypaizzy now!
        </h3>
        <.button>Download the Scratchbac app</.button>
        <span class="text-sm text-gray-500">
          <.link
            navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/users/register")}
            class="text-sm text-teal-400 font-bold hover:underline"
          >
            Sign up
          </.link>
          Or
          <.link
            navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/users/log_in")}
            class="text-sm text-teal-400 font-bold hover:underline"
          >
            Sign in
          </.link>
          via Web
        </span>
      </div>
    </div>
    """
  end

  @doc """
   Render a user_profile_banner in show location in current user

     ###Example
     <.user_profile_banner id="orb-user-profile" user={@user} show_location={true}>
      <.link
        :if={@current_user && @user.id == @current_user.id}
        patch={~p"/user/{current_user.username}/edit"}
      >
        <Heroicons.camera class="bottom-4 -ml-6 lg:w-11 lg:h-11 h-10 w-10 fill-white" />
      </.link>
    </.user_profile_banner>

  """

  attr(:id, :string, required: true)
  attr(:navigate, :any)
  slot(:inner_block)
  attr(:user, :map, required: true)
  attr(:show_location, :boolean)

  attr(:show_shadow, :string,
    default:
      "w-full justify-center items-center flex relative top-0 w-full bg-[#FFFFFFB2] dark:bg-[#000000] dark:opacity-60 py-2"
  )

  attr(:show_img, :boolean, default: true)
  attr(:show_border, :boolean, default: true)
  attr(:main_height, :string, default: "lg:h-80")
  attr(:text_color, :string, default: "text-[#404252] dark:text-white")

  @spec user_profile_banner(map) :: Phoenix.LiveView.Rendered.t()
  def user_profile_banner(assigns) do
    assigns =
      assigns
      |> assign(:user, Map.from_struct(assigns.user))
      |> then(fn
        %{show_location: true, user: %{public_profile: %{territories: terr}}} = state ->
          assign(state, :locations, Phos.Utility.Geo.top_occuring(terr, 2))

        state ->
          assign(state, :show_location, false)
      end)

    ~H"""
    <div class="relative rounded-3xl font-poppins">
      <img
        class={[
          @show_img == true && "lg:rounded-3xl",
          "object-cover w-full h-64 rounded-none",
          @main_height
        ]}
        src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/banner/lossless")}
        onerror="this.src='/images/default_banner.jpg';"
      />
      <div class="absolute inset-0 flex flex-col w-full bg-opacity-50">
        <div class={[@show_shadow]}>
          <div class="relative w-full lg:max-w-3xl">
            <div :if={@show_location} class="absolute right-0 z-50 mt-8 mr-2 lg:mr-0 md:mr-10">
              <.user_modal id={"#{@id}-orb-modal-#{@user.username}"} />
            </div>
            <div
              :if={@show_location}
              class="absolute inset-x-2 lg:inset-x-0 md:inset-x-10 flex items-end justify-end gap-1"
            >
              <Heroicons.bookmark class="w-5 h-6 text-gray-900 group-hover:text-teal-500 dark:text-white cursor-pointer" />
              <Heroicons.ellipsis_vertical
                phx-click={JS.toggle(to: "##{@id}-orb-modal-#{@user.username}")}
                class="w-6 h-6 text-gray-900 group-hover:text-teal-500 dark:text-white cursor-pointer"
              />
            </div>
            <div class="flex">
              <div class="flex flex-1 items-center justify-center">
                <p class={[@text_color, "text-center font-bold"]}><%= "@#{@user.username}" %></p>
              </div>
            </div>
          </div>
        </div>
        <.link
          :if={@user.username}
          navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}")}
        >
          <div class="relative flex justify-center items-center mt-6">
            <div class="relative">
              <img
                src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossless")}
                class={[
                  @show_border == true && "dark:border-black",
                  "h-36 w-36 lg:h-40 lg:w-40 border-4 border-white rounded-full object-cover"
                ]}
                onerror="this.src='/images/default_hand.jpg';"
              />
              <span class="lg:hidden block top-3 right-0 absolute w-9 h-9 bg-[#9747FF] rounded-full flex items-center justify-center">
                <Heroicons.plus_small class="w-7 h-7 group-hover:text-teal-500 text-white" />
              </span>
            </div>

            <div
              :if={@inner_block != []}
              class="bottom-0 right-0 inline-block absolute w-14 h-14 bg-transparent"
            >
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </.link>
        <div :if={@show_location} class="flex-1 flex flex-col items-center lg:mt-4 mt-2 lg:px-8">
          <div class="flex items-center space-x-4">
            <div
              :for={location <- @locations}
              class="flex items-center bg-white opacity-75 dark:opacity-100 dark:bg-black text-black  dark:text-white px-2 py-1 rounded-full text-xs lg:text-sm font-semibold font-poppins"
            >
              <.white_location type="white_location" class="dark:fill-white"></.white_location>
              <span class="ml-1"><%= location %></span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:user, :map, required: true)
  attr(:flex, :any, default: nil)
  attr(:id, :string, required: true)
  slot(:actions)
  slot(:allies)

  slot(:ally_button) do
    attr(:user, :map, doc: "user want to attached to")
    attr(:current_user, :map, doc: "current active user")
    attr(:socket, :map, doc: "current active socket")
  end

  slot(:inner_block)

  def user_information_card(assigns) do
    assigns =
      assign(
        assigns,
        :user,
        Map.from_struct(assigns.user)
      )

    ~H"""
    <div class="flex flex-col font-poppins mx-auto w-full lg:mx-0 py-4 lg:py-4 rounded-[19px] shadow-sm lg:bg-[#F9F9F9] bg-gray-100 dark:bg-gray-800">
      <div class="flex justify-between items-center lg:items-start w-full gap-2 lg:px-3.5 px-3">
        <p class="lg:text-3xl text-lg break-words font-bold text-gray-900 dark:text-white text-left  mb-1 lg:mb-0">
          <%= @user |> get_in([:public_profile, Access.key(:public_name, "-")]) %>
        </p>
        <div class="flex gap-2">
          <a
            class="cursor-pointer"
            id={"#{@id}-sharebtn"}
            phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-copylink")}
          >
            <div id={"#{@id}-copylink"} class="hidden">
              <%= PhosWeb.Endpoint.url() <>
                path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}") %>
            </div>
            <.share_btn type="banner" class="h-8 ml-4 dark:fill-white cursor-pointer"></.share_btn>
          </a>
          <%= render_slot(@actions) %>
        </div>
      </div>
      <div class="space-y-1 lg:space-y-2 break-words lg:px-3.5 px-3">
        <p class="lg:text-sm text-xs text-black font-semibold	dark:text-[#D1D1D1]">
          <%= @user |> get_in([:public_profile, Access.key(:occupation, "-")]) %>
        </p>
        <p class="text-black font-normal text-sm dark:text-[#D1D1D1]">
          <%= @user |> get_in([:public_profile, Access.key(:bio, "-")]) %>
        </p>
        <p>
          <span
            :for={trait <- @user |> get_in([:public_profile, Access.key(:traits, "-")])}
            class="text-gray-500 text-sm font-medium dark:text-[#777986]"
          >
            <%= "##{trait}" %>
          </span>
        </p>
        <p class="lg:hidden block text-sm dark:text-white text-black font-semibold hover:underline hover:decoration-purple-600 dark:hover:decoration-white hover:decoration-solid hover:decoration-2 cursor-pointer">
          <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@username}/allies")}>
            <%= "#{@ally_count} | allies with @#{@user.username}'s and Others" %>
          </.link>
        </p>
        <%= render_slot(@allies) %>
      </div>
    </div>
    """
  end

  @doc """
   Render a User_inforamtion_card_orb in desktop view
     ## User Profile , location, Bio , trait

     ###Example
      <.user_information_card_orb
          id="orb-initiator-public-profile"
          user={@orb.initiator}
          flex="">
          <:ally_button current_user={@current_user} user={@orb.initiator} socket={@socket} />
      </.user_information_card_orb>
  """

  attr(:user, :map, required: true)
  attr(:flex, :any, default: nil)
  attr(:id, :string, required: true)
  attr(:show_location, :boolean, default: true)
  slot(:actions)

  slot(:ally_button) do
    attr(:user, :map, doc: "user want to attached to")
    attr(:current_user, :map, doc: "current active user")
    attr(:socket, :map, doc: "current active socket")
  end

  slot(:inner_block)
  slot(:allies)

  def user_information_card_orb(assigns) do
    assigns =
      assigns
      |> assign(:user, Map.from_struct(assigns.user))
      |> then(fn
        %{show_location: true, user: %{public_profile: %{territories: terr}}} = state ->
          assign(state, :locations, Phos.Utility.Geo.top_occuring(terr, 2))

        state ->
          assign(state, :show_location, false)
      end)

    ~H"""
    <div class="flex flex-col p-4 w-full space-y-1 rounded-3xl bg-[#EEEFF3] dark:bg-gray-800 font-poppins space-y-2">
      <h5 class="lg:text-2xl  text-lg font-bold text-[#000000] dark:text-white font-Poppins break-words">
        <%= @user |> get_in([:public_profile, Access.key(:public_name, "-")]) %>
      </h5>

      <p class="text-[#000000] text-base font-semibold dark:text-[#F9F9F9] break-words">
        <%= @user |> get_in([:public_profile, Access.key(:occupation, "-")]) %>
      </p>

      <div class="flex gap-4 items-center justify-center">
        <a
          class="cursor-pointer"
          id={"#{@id}-sharebtn"}
          phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-copylink")}
        >
          <div id={"#{@id}-copylink"} class="hidden">
            <%= PhosWeb.Endpoint.url() <>
              path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}") %>
          </div>
          <.share_btn type="banner" class="h-8 ml-4 dark:fill-white"></.share_btn>
        </a>
        <div :if={@ally_button != []} class="cursor-pointer">
          <.live_component
            :for={ally <- @ally_button}
            id="ally_button"
            module={PhosWeb.Component.AllyButton}
            current_user={ally.current_user}
            user={ally.user}
            parent_pid={ally.parent_pid}
          />
        </div>
      </div>
      <div :if={@show_location}>
        <div class="flex gap-1 justify-center">
          <div
            :for={location <- @locations}
            class="flex items-center bg-gray-50 dark:bg-[#000000] text-[#404252] dark:text-[#F9F9F9] px-1.5 rounded-full lg:text-sm opacity-80 text-xs font-semibold"
          >
            <.orb_location type="orb_location" class="h-8 dark:fill-white"></.orb_location>
            <span class="ml-1"><%= location %></span>
          </div>
        </div>

        <p class="text-gray-700 font-normal	 text-base dark:text-[#F9F9F9]">
          <%= @user |> get_in([:public_profile, Access.key(:bio, "-")]) %>
        </p>

        <span
          :for={trait <- @user |> get_in([:public_profile, Access.key(:traits, "-")])}
          class="text-gray-500 text-base font-normal dark:text-[#777986]"
        >
          <%= "##{trait}" %>
        </span>
        <%= render_slot(@allies) %>
      </div>
    </div>
    """
  end

  @doc """
   Render a Welcome_message new user login or sign up the scartchbac website
  """

  attr(:id, :string, required: true)

  attr(:show, :boolean,
    default: false,
    doc: "Default value is not to show the message"
  )

  attr(:path, :string, default: "/")
  attr(:user, :any, default: nil, doc: "Relational User Object")

  attr(:current_user, :any,
    default: nil,
    doc: "User state to create session / to redirect in app"
  )

  def welcome_message(assigns) do
    ~H"""
    <.ally_modal id={@id} background="bg-black/50" close_button={true} main_width="lg:max-w-lg">
      <div
        id={"#{@id}-main-content"}
        data-selector="phos_modal_message"
        class="w-full flex flex-col items-center bg-white lg:rounded-3xl lg:shadow-2xl dark:bg-gray-800 font-poppins space-y-3 lg:px-32 p-6 md:px-14 px-10"
      >
        <div :if={@user} class="flex flex-col justify-center items-center">
          <img
            src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
            class="h-40 w-40 rounded-full object-cover"
          />
          <p class="font-semibold text-base dark:text-white">Hmm...You were saying?</p>
          <p :if={@user.username} class="text-sm text-center text-[#777986] dark:text-gray-400">
            <%= "Join the tribe to share your thoughts with #{@user.username} now!" %>
          </p>
        </div>
        <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/redirect/#{@path}")}>
          <.button tone={:primary}>Download Scratchbac App</.button>
        </.link>
        <div
          :if={is_nil(@current_user) && PhosWeb.Endpoint.url() |> String.contains?("localhost")}
          class="text-sm text-gray-500 "
        >
          <.link
            navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/users/register")}
            class="text-sm text-purple-400 font-bold hover:underline"
          >
            Sign up
          </.link>
          Or
          <.link
            navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/users/log_in")}
            class="text-sm text-purple-400 font-bold hover:underline"
          >
            Sign in
          </.link>
          via Web
        </div>
      </div>
    </.ally_modal>
    """
  end

  @doc """
   Render a chip is action of the orb view user express the recation
  """
  attr(:emoji, :any)

  def chip(assigns) do
    ~H"""
    <div class="flex gap-1 p-1 font-poppins">
      <div
        :for={emo <- @emoji}
        class="rounded-2xl bg-transparent	border border-gray-200 px-1 hover:bg-gray-200+"
      >
        <span><%= emo.sticker %>
          <span class="ml-2 text-white text-sm font-bold"><%= emo.count %></span></span>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:memories, :any)
  attr(:current_user, :map, required: true)
  attr(:timezone, :string)

  def list_message(assigns) do
    ~H"""
    <div id={"#{@id}-list"}>
      <div class="relative lg:h-[860px] h-[800px]">
        <img src="/images/light_bg.jpeg" class="inset-0 w-full h-full object-cover" />
        <div
          id="message_container"
          phx-hook="ScrollTop"
          class="journal-scroll absolute inset-0 overflow-y-auto"
        >
          <div
            id="message_stream"
            phx-update="stream"
            class="relative w-full py-2 mb-20 lg:px-56 px-0"
          >
            <div :for={{dom_id, memory} <- @memories} } id={dom_id}>
              <.scry_memory
                id={dom_id}
                memory={memory}
                current_user={@current_user}
                timezone={@timezone}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:memory, :any)
  attr(:current_user, :map, required: true)
  attr(:timezone, :string)

  @spec scry_memory(map) :: Phoenix.LiveView.Rendered.t()
  def scry_memory(assigns) do
    assigns =
      assigns
      |> assign(
        :media,
        Phos.Orbject.S3.get_all!("MEM", assigns.memory.id, "public/profile")
        |> (fn
              nil ->
                []

              media ->
                for {path, url} <- media do
                  %Phos.Orbject.Structure.Media{
                    ext: MIME.from_path(path),
                    path: "public/profile" <> path,
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
      )

    ~H"""
    <div id={"#{@id}-list"} class="overflow-y-auto my-2">
      <ul class="relative w-full lg:px-2 font-poppins px-4 md:px-10">
        <%= if @memory.user_source_id != @current_user.id do %>
          <li class="flex justify-start">
            <div class="max-w-xs bg-[#F9F9F9] rounded-2xl dark:bg-[#404252]">
              <.img_preview
                :if={@media != []}
                archetype="MEM"
                uuid={@memory.id}
                path="public/profile"
                current_user={@current_user}
                id={"#{@id}-scry-memory-#{@memory.id}"}
                media={@media}
                memory={@memory}
              />
              <.memory_information
                memory={@memory}
                timezone={@timezone}
                id={"#{@id}-scry-memory-#{@memory.id}"}
              />
            </div>
          </li>
        <% end %>
        <%= if @memory.user_source_id == @current_user.id do %>
          <li class="flex justify-end">
            <div class="max-w-xs bg-[#C9F8F3] dark:bg-[#00615A] rounded-2xl">
              <.img_preview
                :if={@media != []}
                archetype="MEM"
                uuid={@memory.id}
                path="public/profile"
                id={"#{@id}-scry-memory-#{@memory.id}"}
                media={@media}
                memory={@memory}
                current_user={@current_user}
              />
              <.memory_information
                memory={@memory}
                timezone={@timezone}
                id={"#{@id}-scry-memory-#{@memory.id}"}
              />
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:archetype, :string, required: true)
  attr(:uuid, :string, required: true)
  attr(:path, :string)
  attr(:media, :any)
  attr(:memory, :any)
  attr(:current_user, :map, required: true)

  def img_preview(assigns) do
    assigns = assign(assigns, :num_images, min(length(assigns.media), 5))

    ~H"""
    <div :if={!is_nil(@media)} id={"#{@id}-image-wrapper"}>
      <div class="grid grid-cols-2">
        <div :for={m <- Enum.take(@media, floor(@num_images / 2) * 2)}>
          <.link
            class="relative"
            patch={unverified_path(PhosWeb.Endpoint, PhosWeb.Router, "/memories/media/#{@memory.id}")}
          >
            <img
              class={["cursor-zoom-in", "h-40 w-40 object-cover", @class]}
              src={m.url}
              loading="lazy"
            />
          </.link>
        </div>
        <div :if={rem(@num_images, 2) == 1} class="col-span-2">
          <.link
            class="relative"
            patch={unverified_path(PhosWeb.Endpoint, PhosWeb.Router, "/memories/media/#{@memory.id}")}
          >
            <img
              class={["cursor-zoom-in", "h-40 w-full object-cover", @class]}
              src={@media |> Enum.at(-1) |> Map.get(:url)}
              loading="lazy"
            />
          </.link>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:memory, :any)
  attr(:timezone, :string)

  def memory_information(assigns) do
    ~H"""
    <div id={"#{@id}-memory-info"}>
      <div class="relative px-2 py-1.5 font-poppins">
        <span class="flex flex-col text-sm font-normal text[#404252] dark:text-[#D1D1D1]">
          <%= @memory.message %>
        </span>
        <span class="text-[10px] flex justify-end text-gray-700 dark:text-[#D2D4DA]">
          <%= get_time(@memory.inserted_at, @timezone) %>
        </span>
        <.orb_link :if={not is_nil(@memory.orb_subject_id)} orb={@memory.orb_subject} />
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:user, :any)
  slot(:actions)

  def chat_profile(assigns) do
    ~H"""
    <div class="flex w-full items-center justify-between bg-[#FBFBFB] lg:bg-white px-3 py-2 lg:shadow-none shadow-lg shadow-[FBFBFB] dark:bg-gray-900 lg:dark:bg-gray-800">
      <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/memories")}>
        <Heroicons.arrow_small_left class="h-5 w-5 text-[#777777] dark:text-[#D1D1D1]" />
      </.link>
      <div class="flex items-center">
        <p class="text-base font-semibold text-[#404252] dark:text-[#D1D1D1]">
          <%= @user.username %>
        </p>
      </div>
      <.link
        class="flex shrink-0"
        navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}")}
      >
        <img
          class="object-cover lg:w-14 lg:h-14 h-12 w-12 rounded-full"
          src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
          alt="username"
          onerror="this.src='/images/default_hand.jpg';"
        />
      </.link>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{}, doc: "JS cancel action")
  attr(:on_confirm, JS, default: %JS{}, doc: "JS confirm action")
  attr(:close_button, :boolean, default: true)
  attr(:background, :string, default: "bg-white")
  slot(:inner_block, required: true)
  slot(:title)
  slot(:subtitle)
  slot(:information)

  def gallerymodal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      class="fixed z-10 inset-0 hidden  w-full mx-auto h-screen"
      aria-hidden="true"
    >
      <div class="w-full h-screen fixed inset-0 overflow-y-auto journal-scroll transition-opacity bg-white/90 dark:bg-black/90">
        <.focus_wrap
          id={"#{@id}-container"}
          phx-mounted={@show && show_modal(@id)}
          phx-window-keydown={hide_modal(@on_cancel, @id)}
          phx-key="escape"
          phx-click-away={hide_modal(@on_cancel, @id)}
          class="hidden relative h-screen flex flex-col"
        >
          <div :if={@close_button} class="absolute top-4 right-4 lg:top-4 lg:right-6">
            <button
              phx-click={hide_modal(@on_cancel, @id)}
              type="button"
              class="opacity-80 hover:opacity-40 "
              aria-label={gettext("close")}
            >
              <Heroicons.x_mark class="h-6 w-6 dark:text-white" />
            </button>
          </div>
          <div id={"#{@id}-content"}>
            <div>
              <header class="flex px-2 py-3 bg-white dark:bg-gray-900 lg:dark:bg-gray-800 items-center justify-center">
                <h1
                  id={"#{@id}-title"}
                  class="dark:text-white lg:text-2xl text-lg font-semibold text-gray-800"
                >
                  <%= render_slot(@title) %>
                </h1>
              </header>
            </div>
            <div id={"#{@id}-main"} class="flex flex-1 items-center justify-center">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </.focus_wrap>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{}, doc: "JS cancel action")
  attr(:on_confirm, JS, default: %JS{}, doc: "JS confirm action")
  attr(:background, :string, default: "bg-white")
  attr(:close_button, :boolean, default: true)
  attr(:main_width, :string, default: "w-full")

  slot(:inner_block, required: true)

  slot(:confirm) do
    attr(:tone, :atom)
  end

  slot(:cancel)

  def ally_modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      class="relative z-50 hidden w-full mx-auto h-screen bg-white/50 dark:bg-black/50 transition-opacity"
    >
      <div
        id={"#{@id}-bg"}
        class={["fixed inset-0 bg-zinc-50/90 transition-opacity", @background]}
        aria-hidden="true"
      />
      <div class="fixed inset-0 w-full flex">
        <div
          aria-describedby={"#{@id}-description"}
          role="dialog"
          aria-modal="true"
          tabindex="0"
          class="w-full"
        >
          <div class="flex w-full h-screen lg:items-center lg:justify-center items-end justify-end">
            <div class={["w-full lg:py-8", @main_width]}>
              <.focus_wrap
                id={"#{@id}-container"}
                phx-mounted={@show && show_modal(@id)}
                phx-window-keydown={hide_modal(@on_cancel, @id)}
                phx-key="escape"
                phx-click-away={hide_modal(@on_cancel, @id)}
                class="hidden relative flex w-full bg-white shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition lg:rounded-3xl lg:shadow-2xl"
              >
                <div :if={@close_button} class="absolute top-4 right-4">
                  <button
                    phx-click={hide_modal(@on_cancel, @id)}
                    type="button"
                    class="-m-3 flex-none p-3 opacity-80 hover:opacity-40"
                    aria-label={gettext("close")}
                  >
                    <Heroicons.x_mark class="h-5 w-5 dark:text-white text-gray-900" />
                  </button>
                </div>
                <div id={"#{@id}-content"}>
                  <div
                    id={"#{@id}-main"}
                    class="w-full lg:max-w-2xl lg:items-center lg:justify-center flex"
                  >
                    <%= render_slot(@inner_block) %>
                  </div>
                  <div
                    :if={@confirm != [] or @cancel != []}
                    class="p-4 flex flex-row-reverse items-center gap-5"
                  >
                    <.button
                      :for={confirm <- @confirm}
                      id={"#{@id}-confirm"}
                      tone={Map.get(confirm, :tone, :primary)}
                      phx-click={@on_confirm}
                      phx-disable-with
                      class="py-2 px-3"
                    >
                      <%= render_slot(confirm) %>
                    </.button>
                    <.link
                      :for={cancel <- @cancel}
                      phx-click={hide_modal(@on_cancel, @id)}
                      class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                    >
                      <%= render_slot(cancel) %>
                    </.link>
                  </div>
                </div>
              </.focus_wrap>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:navigate, :any)
  slot(:inner_block)
  attr(:user, :map, required: true)
  attr(:show_location, :boolean)
  slot(:actions)
  attr(:username, :string)

  slot(:ally_button) do
    attr(:user, :map, doc: "user want to attached to")
    attr(:current_user, :map, doc: "current active user")
    attr(:socket, :map, doc: "current active socket")
  end

  def redirect_user(assigns) do
    assigns =
      assigns
      |> assign(:user, Map.from_struct(assigns.user))
      |> then(fn
        %{show_location: true, user: %{public_profile: %{territories: terr}}} = state ->
          assign(state, :locations, Phos.Utility.Geo.top_occuring(terr, 2))

        state ->
          assign(state, :show_location, false)
      end)

    ~H"""
    <div class="font-poppins relative w-full">
      <img class="object-cover w-full h-[26rem] lg:h-[32rem]" src="/images/bg.jpg" />
      <div class="absolute dark:bg-[#000000] bg-white inset-0 bg-opacity-50 dark:bg-opacity-70 px-4 md:px-10">
        <div class="flex flex-col items-center justify-center">
          <img
            src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossless")}
            class="h-36 w-36 lg:h-44 lg:w-44 rounded-full object-cover mt-8 img-double-border"
            onerror="this.src='/images/default_hand.jpg';"
          />
          <div :if={@show_location} class="flex-1 flex flex-col items-center mt-4 lg:px-8">
            <div class="flex items-center space-x-4">
              <div
                :for={location <- @locations}
                class="flex items-center bg-white opacity-75 dark:opacity-100 text-black  px-1.5 py-0.5 rounded-full text-sm lg:text-base font-semibold font-poppins"
              >
                <.white_location type="white_location" class=""></.white_location>
                <span class="ml-1"><%= location %></span>
              </div>
            </div>
          </div>
        </div>
        <div class="flex flex-col font-poppins mt-4 mx-auto w-full px-4 md:px-10 py-2 rounded-[19px] bg-gray-200 bg-opacity-80 dark:bg-[#FCFCFC] dark:bg-opacity-10">
          <div class="flex justify-between items-center w-full gap-2">
            <p class="lg:text-3xl md:text-2xl text-xl break-words font-bold text-gray-900  dark:text-white text-left  mb-1 lg:mb-0">
              <%= @user |> get_in([:public_profile, Access.key(:public_name, "-")]) %>
            </p>
            <div class="flex gap-2">
              <a
                id={"#{@id}-sharebtn"}
                phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-copylink")}
              >
                <div id={"#{@id}-copylink"} class="hidden">
                  <%= PhosWeb.Endpoint.url() <>
                    path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}") %>
                </div>
                <.share_btn type="banner" class="h-8 ml-4 dark:fill-white"></.share_btn>
              </a>
              <%= render_slot(@actions) %>
            </div>
          </div>
          <div class="space-y-1 md:space-y-2 break-words">
            <p class="lg:text-base md:text-sm text-xs text-black font-semibold mt-0.5 dark:text-[#D1D1D1]">
              <%= @user |> get_in([:public_profile, Access.key(:occupation, "-")]) %>
            </p>
            <p class="text-black font-normal text-sm md:text-base dark:text-[#D1D1D1]">
              <%= @user |> get_in([:public_profile, Access.key(:bio, "-")]) %>
            </p>
            <span
              :for={trait <- @user |> get_in([:public_profile, Access.key(:traits, "-")])}
              class="text-gray-500 text-sm  md:text-base font-medium dark:text-[#777986]"
            >
              <%= "##{trait}" %>
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_date(time, timezone) do
    time
    |> DateTime.from_naive!("UTC")
    |> Timex.shift(minutes: trunc(timezone.timezone_offset))
    |> Timex.format("{0D}-{0M}-{YYYY}")
    |> elem(1)
  end

  defp get_time(time, timezone) do
    time
    |> DateTime.from_naive!("UTC")
    |> Timex.shift(minutes: trunc(timezone.timezone_offset))
    |> Timex.format("{h12}:{m} {AM}")
    |> elem(1)
  end
end
