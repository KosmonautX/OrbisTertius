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
  import Phoenix.HTML

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
      class="relative z-50 hidden bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-400 dark:border-gray-700 dark:hover:bg-gray-700 px-2 w-full mx-auto justify-center items-center"
    >
      <div
        id={"#{@id}-bg"}
        class={["fixed inset-0 bg-zinc-50/90 transition-opacity", @background]}
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
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
              class="hidden relative rounded-2xl shadow-lg bg-white shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition"
            >
              <div :if={@close_button} class="absolute top-4 right-4">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <Heroicons.x_mark solid class="h-5 w-5 stroke-current" />
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
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, default: "flash", doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:autoshow, :boolean, default: true, doc: "whether to auto show the flash on mount")
  attr(:close, :boolean, default: true, doc: "whether the flash can be closed")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("#flash")}
      role="alert"
      class={[
        "absolute  hidden top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-lg shadow-zinc-900/5 ring-1",
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
  attr(:as, :any, default: nil, doc: "the server side parameter to collect all input under")
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
        "space-y-4 bg-white font-poppins mt-4 dark:bg-gray-900 dark:border-gray-700 w-full",
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

  attr(:type, :string, default: "button", values: ~w(button submit reset), doc: "Type of button")
  attr(:class, :string, default: "")
  attr(:rest, :global, include: ~w(disabled form name value), doc: "Rest of html attribute")

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
  defp button_class(:primary), do: "bg-teal-400 hover:bg-teal-600 text-white dark:text-black"
  defp button_class(:warning), do: "bg-yellow-400 hover:bg-yellow-600"
  defp button_class(:success), do: "bg-green-400 hover:bg-green-600"
  defp button_class(:dark), do: "bg-slate-800 hover:bg-black text-white"

  defp button_class(:icons),
    do:
      "font-poppins inline-block text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 focus:ring-4 focus:outline-none focus:ring-gray-200 dark:focus:ring-gray-700 rounded-sm text-sm"

  defp default_button_class do
    [
      "phx-submit-loading:opacity-75",
      "rounded-lg",
      "font-poppins",
      "px-3",
      "py-2",
      "text-sm",
      "font-bold",
      "leading-6",
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
  attr(:multiple, :boolean, default: false, doc: "the multiple flag for select inputs")
  attr(:rest, :global, include: ~w(hide_error autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step))
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
    assigns = assign_new(assigns, :checked, fn -> input_equals?(assigns.value, "true") end)

    ~H"""
    <label phx-feedback-for={@name} class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        id={@id || @name}
        name={@name}
        value="true"
        checked={@checked}
        class="font-poppins rounded text-teal-600 bg-gray-100 border-gray-300 rounded focus:ring-teal-500 focus:ring-teal-900 dark:focus:ring-teal-600 dark:ring-offset-gray-800 dark:focus:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
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
        class="font-poppins mt-1 block w-full py-2 px-3 border border-gray-300 bg-white rounded-lg shadow-sm focus:outline-none focus:ring-zinc-500 focus:border-zinc-500 sm:text-sm"
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
          "font-poppins w-full rounded-3xl border border-gray-300 px-4 bg-white text-base text-gray-900 focus:border-teal-500 focus:ring-teal-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white placeholder-gray-400 dark:focus:border-teal-500 dark:focus:ring-teal-500 py-3",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5"
        ]}
        {@rest}
      >

    <%= @value %></textarea>
    </div>
    """
  end

  def input(%{type: "textarea", rest: %{class: _class}} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={[@rest.class]}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        rows="1"
        id={@id || @name}
        name={@name}
        class={[
          input_border(@errors),
          "font-poppins w-full rounded-3xl border border-gray-300 px-4 bg-white text-base text-gray-900 focus:border-teal-500 focus:ring-teal-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white placeholder-gray-400 dark:focus:border-teal-500 dark:focus:ring-teal-500 py-3",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5"
        ]}
        {@rest}
      >

    <%= @value %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id || @name}
        rows="1"
        name={@name}
        class={[
          input_border(@errors),
          "font-poppins mx-6 w-full rounded-lg border border-gray-300 bg-white p-2 text-sm text-gray-900 focus:border-teal-500 focus:ring-teal-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:placeholder-gray-400 dark:focus:border-teal-500 dark:focus:ring-teal-500
          "
        ]}
        {@rest}
      >

    <%= @value %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
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
          "mt-2 block w-full rounded-lg border-zinc-300 dark:bg-gray-600 dark:border-gray-500 dark:placeholder-gray-400 dark:text-white py-[7px] px-[11px] font-poppins",
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
    do: "border-rose-400 focus:border-rose-400 focus:ring-rose-400/10"

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

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def table(assigns) do
    ~H"""
    <div
      id={@id}
      class="relative w-full flex flex-col bg-white border-0 border-transparent border-solid shadow-xl p-2 overflow-scroll font-poppins"
    >
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
    <div class="flex max-w-sm font-poppins">
      <div>
        <img
          src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossy")}
          onerror="this.src='/images/default_banner.jpg';"
          class="xl:h-14 xl:w-14 lg:w-12 lg:h-12 mr-4 object-cover rounded-full "
          alt="user5"
        />
      </div>
      <div class="flex flex-col xl:ml-1 lg:ml-2 -mb-2">
        <h6 class="mb-0 leading-normal text-sm font-bold"><%= "#{@user.username}" %></h6>
        <p class="mb-0 leading-tight text-sm text-gray-400"><%= "#{@user.email}" %></p>
      </div>
    </div>
    """
  end

  attr(:user, :map, required: true)
  attr(:id, :string, required: true)

  @doc """
  Render a Admin Grid Using in Mobile Responsive Admin Dashboard

  ## Examples
  <.admin_grid user={orb.initiator}></.admin_grid>
  """

  @spec admin_grid(map) :: Phoenix.LiveView.Rendered.t()
  def admin_grid(assigns) do
    ~H"""
    <div class="w-full  bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800     dark:border-gray-700 flex flex-col items-center py-2 font-poppins">
      <img
        class="w-24 h-24 mb-3 rounded-full shadow-lg object-cover"
        src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossless")}
        alt=""
        onerror="this.src='/images/default_hand.jpg';"
      />

      <div class="p-2">
        <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          <%= "#{@user.username}" %>
        </h5>

        <p class="text-gray-400 text-sm font-semibold flex flex-col gap-1">
          <span class="flex"><Heroicons.user class="w-4 h-4 dark:text-white mr-2" /> USER NAME</span>
          <span class="mb-3 font-bold text-gray-800 text-base dark:text-gray-400">
            <%= @user |> get_in([Access.key(:public_profile, %{}), Access.key(:public_name, "")]) %>
          </span>
        </p>

        <p class="text-gray-400 font-semibold text-sm flex flex-col gap-1">
          <span class="flex">
            <Heroicons.calendar class="w-4 h-4 dark:text-white mr-2" /> REVIEW DATE
          </span>
          <span class="mb-3 font-bold text-gray-800 text-base dark:text-gray-400">
            <%= @user |> get_in([Access.key(:public_profile, %{}), Access.key(:birthday, "")]) %>
          </span>
        </p>

        <p class="text-gray-400 font-semibold flex flex-col gap-1 text-sm">
          <span class="flex">
            <Heroicons.adjustments_horizontal class="w-4 h-4 dark:text-white mr-2" />TAGS
          </span>
          <span
            :for={
              trait <-
                @user |> get_in([Access.key(:public_profile, %{}), Access.key(:traits, nil)]) || []
            }
            class="mb-3 font-bold text-gray-800 text-base dark:text-gray-400"
          >
            <%= "#{trait}" %>
          </span>
        </p>
      </div>
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

  attr(:type, :string, default: "normal", values: ["normal", "stripped"], doc: "List type")

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
    <div class={["flex flex-col min-w-0 break-words w-full mb-6 shadow-lg rounded", @class]} {@rest}>
      <div class="rounded-t mb-0 px-4 py-3 border-0 font-poppins">
        <h1 class="font-semibold text-lg text-gray-700"><%= @title %></h1>
      </div>
      <div class="block w-full overflow-none px-2 py-3">
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

  slot :item, required: true, doc: "the slot for form actions, such as a submit button" do
    attr(:to, :string, required: true)
    attr(:title, :string, required: true)
    attr(:icon, :string, required: true)
    attr(:id, :string)
    attr(:name, :string)
  end

  def admin_navbar(assigns) do
    ~H"""
    <nav class="hidden left-0 lg:block lg:fixed lg:top-16 lg:bottom-0 shadow bg-white flex flex-wrap items-center justify-between relative lg:w-64 z-10 px-2 font-poppins">
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
    <nav class="bg-white fixed w-full z-10 top-0 left-0 border-b border-gray-200 text-base font-bold dark:bg-gray-900  p-3 font-poppins">
      <div class=" flex flex-wrap items-center justify-between mx-auto">
        <a href="" class="flex items-center">
          <.logo type="banner" class="h-8 ml-4 dark:fill-white"></.logo>
        </a>
        <button
          type="button"
          class="lg:hidden block items-center p-2 ml-3 text-sm text-gray-500 rounded-lg  hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600"
        >
          <span class="sr-only">Open main menu</span>
          <Heroicons.bars_3 class="w-6 h-6 text-gray-700 group-hover:text-teal-500 dark:text-white" />
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
    <nav class="bg-white fixed w-full z-10 top-0 left-0 border-b-2 border-gray-200 lg:border-gray-200 text-base font-bold dark:bg-gray-900 px-4 py-3 font-poppins ">
      <div class="flex flex-wrap items-center justify-between mx-auto">
        <a href="/" class="flex items-center">
          <.logo type="banner" class="h-8 dark:fill-white"></.logo>
        </a>
        <div class="flex items-center lg:order-2  flex-col   lg:flex-row     lg:space-x-2 lg:w-auto">
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
            <button id="welcome-button" type="button" phx-click={show_modal("welcome_message")}>
              <.open_app type="open"></.open_app>
            </button>
            <!--<button
              id="theme-toggle"
              type="button"
              class="text-gray-700 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 focus:outline-none focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 rounded-sm text-sm px-2"
            >
              <Heroicons.moon
                mini
                id="theme-toggle-dark-icon"
                class="hidden w-8 h-8 text-gray-700 group-hover:text-teal-500  dark:text-white"
              />
              <Heroicons.sun
                mini
                id="theme-toggle-light-icon"
                class="hidden w-8 h-8 text-gray-700 group-hover:text-teal-500  dark:text-white"
              />
            </button>-->
          </div>
        </div>
        <!--<div class="hidden lg:block items-center justify-between w-full  lg:w-auto">
          <ul class="flex flex-col lg:flex-row lg:space-x-6  text-gray-700 dark:text-gray-400 lg:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white lg:dark:hover:bg-transparent">
            <li>
              <a href="#" class="block lg:hover:text-teal-500">
                People
              </a>
            </li>
            <li>
              <a href="/orb" class="block lg:hover:text-teal-500">
                Explore
              </a>
            </li>
            <li>
              <a href="/memories" class="flex items-center justify-between lg:hover:text-teal-500   ">
                Chats
                <Heroicons.chevron_down solid class="w-4 h-4 ml-1 stroke-current dark:text-white" />
              </a>
            </li>
          </ul>
        </div>-->
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
    <nav class="bg-white px-2 fixed w-full z-10 top-0 left-0 border-b border-gray-200 text-base font-bold p-2 dark:bg-gray-900 font-poppins">
      <div class="flex flex-wrap items-center justify-between mx-auto">
        <a href="//www.scratchbac.com/blog" class="flex items-center">
          <.logo type="banner" class="h-7 ml-4 dark:fill-white"></.logo>
        </a>
        <div class="flex gap-2">
          <button id="welcome-button" type="button" phx-click={show_modal("welcome_message")}>
            <.open_app type="open"></.open_app>
          </button>
          <!--<button
            id="theme-toggle"
            type="button"
            class="text-gray-700 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 focus:outline-none focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 rounded-sm text-sm p-2 "
          >
            <Heroicons.moon
              mini
              id="theme-toggle-dark-icon"
              class="hidden w-8 h-8 text-gray-700 group-hover:text-teal-500  dark:text-white"
            />
            <Heroicons.sun
              mini
              id="theme-toggle-light-icon"
              class="hidden w-8 h-8 text-gray-700 group-hover:text-teal-500  dark:text-white"
            />
          </button>-->
        </div>
      </div>
    </nav>
    """
  end

  @doc """
  Render the bottom_banner is help in direct link to playstore using app download
  """
  def bottom_banner(assigns) do
    ~H"""
    <div class="hidden lg:block fixed z-10 bottom-0 w-full border border-gray-200 rounded-lg shadow bg-gray-800 dark:border-gray-700 p-2 font-poppins">
      <div class="flex gap-4 items-end justify-end ">
        <button class="w-full sm:w-auto bg-gray-800 hover:bg-gray-700 focus:ring-4 focus:outline-none focus:ring-gray-300 text-white rounded-lg inline-flex items-center justify-center px-4 py-2.5 dark:bg-gray-700 dark:hover:bg-gray-600 dark:focus:ring-gray-700 border-2 border-white">
          <svg
            class="mr-3 w-7 h-7"
            aria-hidden="true"
            focusable="false"
            data-prefix="fab"
            data-icon="apple"
            role="img"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 384 512"
          >
            <path
              fill="currentColor"
              d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"
            >
            </path>
          </svg>
          <div class="text-left">
            <div class="mb-1 text-xs">Download on the</div>
            <div class="-mt-1 font-sans text-sm font-semibold">Mac App Store</div>
          </div>
        </button>
        <button class="w-full sm:w-auto bg-gray-800 hover:bg-gray-700 focus:ring-4 focus:outline-none focus:ring-gray-300 text-white rounded-lg inline-flex items-center justify-center px-4 py-2.5 dark:bg-gray-700 dark:hover:bg-gray-600 dark:focus:ring-gray-700 border-2 border-white">
          <svg
            class="mr-3 w-7 h-7"
            aria-hidden="true"
            focusable="false"
            data-prefix="fab"
            data-icon="google-play"
            role="img"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 512 512"
          >
            <path
              fill="currentColor"
              d="M325.3 234.3L104.6 13l280.8 161.2-60.1 60.1zM47 0C34 6.8 25.3 19.2 25.3 35.3v441.3c0 16.1 8.7 28.5 21.7 35.3l256.6-256L47 0zm425.2 225.6l-58.9-34.1-65.7 64.5 65.7 64.5 60.1-34.1c18-14.3 18-46.5-1.2-60.8zM104.6 499l280.8-161.2-60.1-60.1L104.6 499z"
            >
            </path>
          </svg>
          <div class="text-left">
            <div class="mb-1 text-xs">Get in on</div>
            <div class="-mt-1 font-sans text-sm font-semibold">Google Play</div>
          </div>
        </button>
      </div>
    </div>
    """
  end

  attr(:current_user, :map, required: true)

  def tabs_mobile(assigns) do
    ~H"""
    <div class="w-full border-gray-400 border-t-2 rounded-t-2xl bg-white  lg:hidden block fixed z-10 bottom-0 px-2 py-1 dark:bg-gray-900 font-poppins">
      <ul class="flex flex-wrap items-center justify-between mx-auto">
        <li>
          <a
            class="block hover:text-teal-400 text-gray-600"
            onclick="changeAtiveTab(event,'user-tab')"
          >
            <Heroicons.user_plus class="w-8 h-8 dark:text-white" />
          </a>
        </li>
        <li>
          <a
            href="/orb"
            class="block hover:text-teal-400 text-gray-600"
            onclick="changeAtiveTab(event,'location')"
          >
            <Heroicons.map_pin class="w-8 h-8 dark:text-white" />
          </a>
        </li>
        <li>
          <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/new")}>
            <Heroicons.plus_circle class="hover:text-teal-400 text-gray-600 w-8 h-8 dark:text-white" />
          </.link>
        </li>
        <li>
          <a
            class="block hover:text-teal-400 text-gray-600 relative inline-block"
            onclick="changeAtiveTab(event,'chat')"
          >
            <Heroicons.chat_bubble_oval_left class="w-8 h-8 dark:text-white" />
            <span class="absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white transform translate-x-1/2 -translate-y-1/2 bg-red-600 rounded-full">
              0
            </span>
          </a>
        </li>
        <li>
          <.link
            :if={not is_nil(@current_user.username)}
            navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@current_user.username}")}
          >
            <img
              class="h-10 w-10 border-4 border-white rounded-full object-cover"
              src={Phos.Orbject.S3.get!("USR", Map.get(@current_user, :id), "public/banner/lossless")}
              onerror="this.src='/images/default_banner.jpg';"
            />
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Render the  tabs_profile its help to mobile responsive tabs in profile view
  """

  attr(:action, :atom)
  attr(:username, :string)
  attr(:id, :string)

  def tabs_profile(assigns) do
    ~H"""
    <div id={@id} class="w-full sticky top-0 left-0 right-0 font-poppins">
      <ul class="flex justify-center font-semibold text-base  text-gray-500 dark:text-white bg-white gap-x-30">
        <li class={[
          (@action == :show && "text-black border-black active") ||
            "border-transparent hover:text-gray-600  hover:border-gray-300",
          "flex-1 border-b-2 GROUP text-center py-3"
        ]}>
          <.link patch={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@username}")}>
            Posts
          </.link>
        </li>

        <li class={[
          (@action == :allies && "text-black border-black active") ||
            "border-transparent hover:text-gray-300  hover:border-gray-300",
          "flex-1 border-b-2 GROUP text-center py-3"
        ]}>
          <.link patch={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@username}/allies")}>
            Allies
          </.link>
        </li>
      </ul>
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
  attr(:user, :any)
  slot(:actions)
  slot(:information)

  def user_info_bar(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        @show_padding == true && "lg:px-4",
        "w-full bg-white  lg:py-2 py-4 flex items-center justify-between dark:bg-gray-900 dark:border dark:border-white px-4 font-poppins",
        @class
      ]}
    >
      <div class="flex">
        <.link
          :if={@user.username}
          navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}")}
        >
          <img
            src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
            class="lg:w-14 lg:h-14 h-12 w-12 rounded-full object-cover shrink-0"
            onerror="this.src='/images/default_hand.jpg';"
          />
        </.link>
        <div class="flex flex-col justify-center -mt-2 ml-1.5">
          <.link
            :if={@user.username}
            navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}")}
          >
            <p class="font-bold text-gray-900 dark:text-white text-base truncate">
              <%= "@#{@user.username}" %>
            </p>
          </.link>

          <p class="flex items-center text-sm text-gray-700 dark:text-gray-400">
            <%= render_slot(@information) %>
          </p>
        </div>
      </div>
      <div class="flex justify-end gap-2"><%= render_slot(@actions) %></div>
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
  attr(:class, :string, default: nil)

  def scry_orb(assigns) do
    assigns =
      assigns
      |> assign(
        :orb_location,
        assigns.orb |> get_in([Access.key(:payload, %{}), Access.key(:where, "-")]) ||
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
                    path: path,
                    url: url,
                    resolution:
                      path |> String.split(".") |> hd() |> String.split("/") |> List.last()
                  }
                end
            end).()
        |> Enum.filter(fn m -> m.resolution == "lossless" end)
      )

    ~H"""
    <div class="rounded-b-lg">
      <.user_info_bar class="lg:rounded-t-3xl" id={"#{@id}-scry-orb-#{@orb.id}"} user={@orb.initiator}>
        <:information :if={!is_nil(@orb_location)}>
          <span class="mr-1">
            <.location type="location" class="h-8 dark:fill-white"></.location>
          </span>
          <%= @orb_location %>
        </:information>
        <:actions>
          <button
            id={"#{@id}-scry-orb-#{@orb.id}-sharebtn"}
            phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-scry-orb-#{@orb.id}-copylink")}
            class="inline-flex items-center focus:outline-none focus:ring-4 focus:ring-gray-200 rounded-2xl"
          >
            <div id={"#{@id}-scry-orb-#{@orb.id}-copylink"} class="hidden">
              <%= PhosWeb.Endpoint.url() <>
                path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}") %>
            </div>
            <.share_btn type="banner" class="h-8 ml-4 dark:fill-white"></.share_btn>
          </button>
          <%= render_slot(@user_action) %>
        </:actions>
      </.user_info_bar>

      <.media_carousel
        :if={@media != []}
        archetype="ORB"
        uuid={@orb.id}
        path="public/banner"
        id={"#{@id}-scry-orb-#{@orb.id}"}
        orb={@orb}
        timezone={@timezone}
        media={@media}
        show_information={@show_information}
      />

      <.link class="relative" navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}")}>
        <.orb_information
          :if={@media == [] || not @show_information}
          id={"#{@id}-scry-orb-#{@orb.id}"}
          title={get_in(@orb, [Access.key(:payload), Access.key(:inner_title)]) || @orb.title}
          show_link={true}
        />
        <.orb_information
          :if={!is_nil(get_in(@orb, [Access.key(:payload), Access.key(:info)]))}
          id={"#{@id}-scry-orb-#{@orb.id}"}
          title={@orb.payload.info}
          show_link={true}
        />
      </.link>
      <.orb_action
        :if={@media == [] || not @show_information}
        id={"#{@id}-scry-orb-#{@orb.id}"}
        orb={@orb}
        date={@timezone}
        show_information={@show_information}
      />
    </div>
    """
  end

  @spec media_carousel(map) :: Phoenix.LiveView.Rendered.t()
  @doc """
   User Post Image and video using js in carousel

  """
  attr(:class, :string, default: nil)
  attr(:id, :string, required: true)
  attr(:archetype, :string, required: true)
  attr(:uuid, :string, required: true)
  attr(:path, :string)
  attr(:orb, :any)
  attr(:timezone, :string)
  attr(:show_information, :boolean, default: true)
  attr(:media, :any)

  def media_carousel(assigns) do
    ~H"""
    <div :if={!is_nil(@media)} id={"#{@id}-carousel-wrapper"} class="glide">
      <section
        class="relative flex items-center font-poppins"
        id={"#{@id}-carousel"}
        phx-update="ignore"
        phx-hook="Carousel"
      >
        <div id={"#{@id}-container"} data-glide-el="track" class="glide__track w-full">
          <div class="glide__slides">
            <div :for={m <- @media} class="glide__slide">
              <div class="relative">
                <.link
                  id={"#{@id}-link-#{@orb.id}"}
                  class="relative"
                  navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}")}
                >
                  <img
                    :if={(m.ext |> String.split("/") |> hd) in ["image", "application"]}
                    class={[
                      @show_information == true && "lg:rounded-b-3xl",
                      "h-96 w-full object-cover dark:border dark:border-white",
                      @class
                    ]}
                    src={m.url}
                    loading="lazy"
                  />
                </.link>
                <video
                  :if={(m.ext |> String.split("/") |> hd) in ["video"]}
                  class={[
                    @show_information == true && "lg:rounded-b-3xl",
                    "w-full h-96 aspect-video hover:aspect-square object-cover dark:border dark:border-white rounded-b-lg"
                  ]}
                  muted
                  loop
                  preload="metadata"
                  playsinline
                >
                  <source src={m.url<> "#t=0.5"} type={m.ext} />
                </video>
                <a
                  :if={(m.ext |> String.split("/") |> hd) in ["video"]}
                  class="absolute hover:text-blue-300 inset-0 bg-transparent flex justify-center items-center p-2 hover:cursor-pointer"
                  data-selector="mute"
                  onclick="
                    this.previousElementSibling.muted = !this.previousElementSibling.muted;
                    this.firstElementChild.firstElementChild.classList.toggle('hidden')
                    this.firstElementChild.lastElementChild.classList.toggle('hidden')
                  "
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

        <div
          :if={@show_information}
          class="absolute bottom-0 h-2/5 pointer-events-auto flex flex-col justify-end bg-gradient-to-t from-black/80 to-black/0 w-full flex flex-col lg:border-b-0 lg:rounded-b-xl lg:border-gray-200 dark:border-gray-700"
        >
          <.link
            id={"#{@id}-link-#{@orb.id}-info"}
            class="relative"
            navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}")}
          >
            <.orb_information
              id={"#{@id}-orb-info-#{@orb.id}"}
              title={@orb.title}
              info_color="prose-invert text-white"
            />
          </.link>
          <!-- <.chip emoji={[
            %{sticker: "😊", count: "20"},
            %{sticker: "❤️", count: "60"},
            %{sticker: "🥹", count: "50"},
            %{sticker: "🫠", count: "30"}
          ]} /> -->
          <div class="items-end">
            <.orb_action
              :if={@orb.media}
              id={"#{@id}-scry-orb-#{@orb.id}"}
              orb={@orb}
              date={@timezone}
              main_color="text-white"
            />
          </div>
        </div>

        <div :if={length(@media) > 1} data-glide-el="controls" class="h-full">
          <div
            data-glide-el="controls[nav]"
            class="absolute flex space-x-3 -translate-x-1/2 bottom-2 left-1/2"
          >
            <button
              :for={count <- Enum.to_list(1..length(@media))}
              class="h-2 w-2 rounded-full bg-white/70 group-hover:bg-white/90 focus:ring-4 focus:ring-white group-focus:outline-none"
              data-glide-dir={"=#{count}"}
            />
          </div>
          <button
            id={"#{@id}-carousel-prev"}
            type="button"
            data-glide-dir="<"
            class="absolute inset-y-2/4	 left-0  flex items-center justify-center  px-2 cursor-pointer group focus:outline-none"
          >
            <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
              <Heroicons.chevron_left class="mt-0.5 h-6 w-6" />
            </span>
          </button>

          <button
            id={"#{@id}-carousel-next"}
            type="button"
            data-glide-dir=">"
            class="absolute inset-y-2/4	 right-0 flex items-center justify-center px-2 cursor-pointer group focus:outline-none"
          >
            <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
              <Heroicons.chevron_right class="mt-0.5 h-6 w-6" />
            </span>
          </button>
        </div>
      </section>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, default: "")
  attr(:info_color, :string, default: "prose-zinc text-gray-600 w-full bg-white dark:bg-gray-900")
  attr(:show_link, :boolean, default: false)

  def orb_information(assigns) do
    assigns =
      assigns
      |> assign(
        :title,
        case Earmark.as_html(assigns.title) do
          {:ok, result, _} -> result |> HtmlSanitizeEx.html5() |> raw()
          _ -> ""
        end)
    # needs to be async and handled on client side scraping

    #   |> assign(:link,
    #   case PhosWeb.Util.DOMParser.extract_link_from_markdown(assigns.title) do
    #   "" -> nil
    #   link when is_binary(link) -> link
    #   _ -> nil
    # end)

    ~H"""
        <div class={["lg:px-4 px-2 py-1 dark:border-x-white font-poppins break-words", @info_color]}>
      <span
        id={"#{@id}-info"}
        class={[
          "prose prose-a:text-blue-500 text-base break-words overflow-hidden font-medium dark:prose-invert w-full",
          @info_color
        ]}
      >
        <%= @title %>
        <!-- <.external_orb_link  :if={@show_link && not is_nil(@link)} link={@link}/> -->
      </span>
    </div>
    """
  end

  @doc """
   Render a External link is use to share hyperlinks
  """
  attr(:link, :string, default: nil)
  def external_orb_link(assigns) do
  assigns = assign(assigns, :page,
        case LinkPreview.create(assigns.link) do
          {:ok, page} -> page
          _ -> nil
    end)

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

  attr(:id, :string, required: true)
  attr(:orb, :any)
  attr(:date, :string)
  attr(:class, :string, default: nil)
  attr(:show_information, :boolean, default: true)
  attr(:main_color, :string, default: "text-gray-600 bg-white dark:bg-gray-900")

  # TODO orb_actions wiring with data
  def orb_action(assigns) do
    ~H"""
    <div
      id={"#{@id}-actions"}
      class={[
        @show_information == true && "lg:rounded-b-3xl",
        "flex justify-between w-full lg:text-sm text-xs px-4 dark:border-b dark:border-b-white mt-2 lg:mt-0 font-poppins",
        @main_color
      ]}
    >
      <span class="dark:text-white">
        <%= get_date(@orb.inserted_at, @date) %>
      </span>
      <div class={[@class, "flex flex-cols"]}>
        <.link
          id={"#{@id}-scry-orb-#{@orb.id}-link"}
          class="relative"
          navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}")}
        >
          <button class="text-center inline-flex items-center dark:text-white">
            <.comment_chat type="comment" class="fill-white"></.comment_chat>
            <span class="ml-1"><%= @orb.comment_count %></span>
          </button>
        </.link>
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
  attr(:show_img, :boolean, default: true)
  attr(:main_height, :string, default: "lg:h-80")

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
    <div class="relative rounded-3xl dark:border dark:border-white font-poppins">
      <img
        class={[
          @show_img == true && "lg:rounded-3xl",
          "object-cover w-full h-64 lg:h-80",
          @main_height
        ]}
        src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/banner/lossless")}
        onerror="this.src='/images/default_banner.jpg';"
      />
      <div class="absolute inset-0 px-6 py-6 flex flex-col items-center bg-opacity-50">
        <p class="text-base lg:text-2xl text-white font-bold mb-2"><%= "@#{@user.username}" %></p>
        <.link
          :if={@user.username}
          navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}")}
        >
          <div class="relative flex justify-center items-center">
            <img
              src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossless")}
              class="h-36 w-36 lg:h-44 lg:w-44 border-4 border-white rounded-full object-cover"
              onerror="this.src='/images/default_hand.jpg';"
            />
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
              class="flex items-center bg-white opacity-75 text-black px-1.5 py-0.5 rounded-full text-sm lg:text-base font-semibold font-poppins"
            >
              <.location type="location" class=""></.location>
              <span class="ml-1"><%= location %></span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
   Render a User_inforamtion_card in Mobile view
     ## User Profile , location, Bio , trait...


     ###Example
      <.user_information_card
          id="orb-initiator-public-profile"
          user={@orb.initiator}
          flex="">
          <:ally_button current_user={@current_user} user={@orb.initiator} socket={@socket} />
        </.user_information_card>
  """

  attr(:user, :map, required: true)
  attr(:flex, :any, default: nil)
  attr(:id, :string, required: true)
  slot(:actions)

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
    <div class="flex flex-col font-poppins mb-4">
      <div class="flex mx-auto w-full justify-between w-full gap-2">
        <p class="lg:text-3xl text-2xl word-break font-extrabold text-gray-900  dark:text-white text-left  inset-y-.5 mb-1 lg:mb-0">
          <%= @user |> get_in([:public_profile, Access.key(:public_name, "-")]) %>
        </p>
        <div class="flex gap-4">
          <a id={"#{@id}-sharebtn"} phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-copylink")}>
            <div id={"#{@id}-copylink"} class="hidden">
              <%= PhosWeb.Endpoint.url() <>
                path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}") %>
            </div>
            <.share_btn type="banner" class="h-8 ml-4 dark:fill-white"></.share_btn>
          </a>
          <%= render_slot(@actions) %>
        </div>
      </div>
      <div class="space-y-2">
        <p class="text-base text-black font-bold dark:text-gray-400">
          <%= @user |> get_in([:public_profile, Access.key(:occupation, "-")]) %>
        </p>
        <p class="text-black font-medium text-sm dark:text-gray-400 mt-1">
          <%= @user |> get_in([:public_profile, Access.key(:bio, "-")]) %>
        </p>
        <div>
          <span
            :for={trait <- @user |> get_in([:public_profile, Access.key(:traits, "-")])}
            class="text-gray-500 text-sm font-medium dark:text-gray-400"
          >
            <%= "##{trait}" %>
          </span>
        </div>
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
    <div class="flex flex-col p-4 w-full space-y-2 rounded-3xl bg-white dark:bg-gray-900 dark:border dark:border-white font-poppins">
      <h5 class="lg:text-2xl  text-lg font-extrabold text-gray-900 dark:text-white font-Poppins">
        <%= @user |> get_in([:public_profile, Access.key(:public_name, "-")]) %>
      </h5>
      <p class="text-black text-base font-semibold dark:text-gray-400">
        <%= @user |> get_in([:public_profile, Access.key(:occupation, "-")]) %>
      </p>
      <div class="flex gap-6 items-center justify-center">
        <a id={"#{@id}-sharebtn"} phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-copylink")}>
          <div id={"#{@id}-copylink"} class="hidden">
            <%= PhosWeb.Endpoint.url() <>
              path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}") %>
          </div>
          <.share_btn type="button" class="h-8 ml-4 dark:fill-white"></.share_btn>
          <%= render_slot(@actions) %>
        </a>
        <div :if={@ally_button != []}>
          <.live_component
            :for={ally <- @ally_button}
            id="ally_button"
            module={PhosWeb.Component.AllyButton}
            current_user={ally.current_user}
            user={ally.user}
            socket={ally.socket}
          />
        </div>
      </div>

      <div :if={@show_location} class="space-y-1">
        <div class="flex  justify-center">
          <div
            :for={location <- @locations}
            class="flex items-center bg-white text-black px-2 py-2 rounded-full lg:text-base text-sm font-bold transition duration-100"
          >
            <.location type="location" class="h-8 ml-4 dark:fill-white"></.location>
            <span class="ml-1"><%= location %></span>
          </div>
        </div>

        <p class="text-gray-700 font-medium text-base dark:text-gray-400">
          <%= @user |> get_in([:public_profile, Access.key(:bio, "-")]) %>
        </p>

        <div>
          <span
            :for={trait <- @user |> get_in([:public_profile, Access.key(:traits, "-")])}
            class="text-gray-500 text-base font-medium dark:text-gray-400"
          >
            <%= "##{trait}" %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  @doc """
   Render a Welcome_message new user login or sign up the scartchbac website
  """

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false, doc: "Default value is not to show the message")
  attr(:path, :string, default: "/")
  attr(:user, :any, default: nil, doc: "User state to create session / to redirect in app")

  def welcome_message(assigns) do
    ~H"""
    <.modal id={@id} background="bg-black/50" close_button={true} main_width="lg:max-w-md max-w-sm">
      <div
        id={"#{@id}-main-content"}
        data-selector="phos_modal_message"
        class="w-full flex flex-col items-center bg-white border border-gray-200 rounded-2xl shadow-2xl hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700 p-6 font-poppins space-y-3 lg:px-16 md:px-14 px-10"
      >
        <div :if={@user} class="flex flex-col justify-center items-center">
          <img
            src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
            class=" h-20 w-20 lg:w-32 lg:h-32 border-4 border-white rounded-full object-cover"
          />
          <p class="font-semibold text-base dark:text-white">Hmm...You were saying?</p>
          <p :if={@user.username} class="text-sm text-center text-gray-400 dark:text-gray-400">
            <%= "Join the tribe to share your thoughts with #{@user.username} now!" %>
          </p>
        </div>
        <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/redirect/#{@path}")}>
          <.modal_open type="modal" class="" />
        </.link>
        <div :if={is_nil(@user)} class="text-sm text-gray-500 ">
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
        </div>
      </div>
    </.modal>
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
  attr(:action, :atom)
  attr(:memories, :any)
  attr(:date, :string)

  @spec last_message(map) :: Phoenix.LiveView.Rendered.t()
  def last_message(assigns) do
    ~H"""
    <ul class="overflow-y-auto h-screen font-poppins">
      <li :for={memory <- @memories}>
        <.link navigate={
          path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/memories/user/#{memory.user_source.username}")
        }>
          <div class="flex items-center px-3 py-2 text-sm transition  duration-150 ease-in-out border-b border-gray-300 cursor-pointer hover:bg-gray-50 focus:outline-none">
            <img
              src={Phos.Orbject.S3.get!("USR", memory.user_source.id, "public/profile/lossless")}
              class="w-14 h-14 border-2 border-teal-500 rounded-full object-cover"
              onerror="this.src='/images/default_hand.jpg';"
            />
            <div class="w-full flex flex-col -mt-4">
              <div class="flex justify-between">
                <span class=" ml-2 text-sm font-bold text-gray-900 dark:text-white ">
                  <%= memory |> get_in([Access.key(:user_source, %{}), Access.key(:username, "-")]) %>
                </span>
                <span class="text-gray-600"><%= get_date(memory.inserted_at, @date) %></span>
              </div>
              <span class="text-gray-700 dark:text-gray-400 ml-2">
                <%= memory.message %>
              </span>
            </div>
          </div>
        </.link>
      </li>
    </ul>
    """
  end

  attr(:id, :string, required: true)
  attr(:current_user, :map, required: true)
  attr(:memories, :any)
  attr(:timezone, :string)

  def list_message(assigns) do
    ~H"""
    <div id={"#{@id}-list"} class=" h-screen overflow-y-auto font-poppins">
      <ul :for={msg <- @memories} class="relative w-full p-1.5">
        <%= if msg.user_source_id != @current_user.id do %>
          <li class="flex justify-start">
            <div class="relative max-w-xl px-4 py-2 text-gray-700 bg-white rounded shadow rounded-l-xl">
              <span class="flex-1 text-xs font-medium leading-relaxed	">
                <%= msg.message %>
                <span class="text-xs flex justify-end">
                  <%= get_time(msg.inserted_at, @timezone) %>
                </span>
              </span>
            </div>
          </li>
        <% end %>
        <%= if msg.user_source_id == @current_user.id do %>
          <li class="flex justify-end">
            <div class="relative max-w-xl px-4 py-2 text-gray-700 bg-amber-300 rounded shadow rounded-l-xl">
              <span class="flex-1 text-xs font-medium leading-relaxed	">
                <%= msg.message %>
                <span class="text-xs flex justify-end">
                  <%= get_time(msg.inserted_at, @timezone) %>
                </span>
              </span>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:user, :any)
  slot(:actions)

  def chat_profile(assigns) do
    ~H"""
    <div class="flex justify-between items-center w-full border-b border-gray-300 px-0.5 font-poppins">
      <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}")}>
        <div class="flex p-1 px-2">
          <img
            class="object-cover w-12 h-12 rounded-full"
            src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
            alt="username"
            onerror="this.src='/images/default_hand.jpg';"
          />
          <span class="block ml-2 font-bold text-gray-600">
            <%= get_in(@user, [Access.key(:public_profile, %{}), Access.key(:public_name, "")]) ||
              @user.username %>
          </span>
        </div>
      </.link>
      <div><%= render_slot(@actions) %></div>
    </div>
    """
  end

  defp get_date(time, timezone) do
    time
    |> DateTime.from_naive!(timezone.timezone)
    |> Timex.shift(minutes: trunc(timezone.timezone_offset))
    |> Timex.format("{D}-{0M}-{YYYY}")
    |> elem(1)
  end

  defp get_time(time, timezone) do
    time
    |> DateTime.from_naive!(timezone.timezone)
    |> Timex.shift(hours: trunc(timezone.timezone_offset))
    |> Timex.format("{h12}:{m} {am}")
    |> elem(1)
  end
end
