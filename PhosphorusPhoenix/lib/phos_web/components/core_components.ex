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
  slot(:confirm)
  slot(:cancel)

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      class="relative z-50 hidden bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-400 dark:border-gray-700 dark:hover:bg-gray-700"
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
        "absolute hidden top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-md shadow-zinc-900/5 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 p-3 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
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
      </.simple_form>
  """
  attr(:for, :any, default: nil, doc: "the datastructure for the form")
  attr(:as, :any, default: nil, doc: "the server side parameter to collect all input under")
  attr(:class, :string, default: nil, doc: "simple form class overide")


  attr(:rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"
  )

  slot(:inner_block, required: true)
  slot(:actions, doc: "the slot for form actions, such as a submit button")

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class={["space-y-4 bg-white mt-4 dark:bg-gray-900 dark:border-gray-700 w-full", @class]}>
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} , @class>
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
    values: ~w(primary success warning danger icons)a,
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
  defp button_class(:primary), do: "bg-teal-400 hover:bg-teal-600"
  defp button_class(:warning), do: "bg-yellow-400 hover:bg-yellow-600"
  defp button_class(:success), do: "bg-green-400 hover:bg-green-600"

  defp button_class(:icons),
    do:
      "inline-block text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 focus:ring-4 focus:outline-none focus:ring-gray-200 dark:focus:ring-gray-700 rounded-sm text-sm"

  defp default_button_class do
    [
      "phx-submit-loading:opacity-75",
      "rounded-lg",
      "px-3",
      "py-2",
      "text-sm",
      "font-bold",
      "leading-6",
      "text-white",
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
  attr(:rest, :global, include: ~w(autocomplete disabled form max maxlength min minlength
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
        class="rounded border-zinc-300 text-zinc-900 focus:ring-zinc-900"
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
        class="mt-1 block w-full py-2 px-3 border border-gray-300 bg-white rounded-md shadow-sm focus:outline-none focus:ring-zinc-500 focus:border-zinc-500 sm:text-sm"
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
          "w-full rounded-lg border border-gray-300 px-2 bg-white text-sm text-gray-900 focus:border-teal-500 focus:ring-teal-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:placeholder-gray-400 dark:focus:border-teal-500 dark:focus:ring-teal-500",
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
          "mx-6 w-full rounded-lg border border-gray-300 bg-white p-2.5 text-sm text-gray-900 focus:border-teal-500 focus:ring-teal-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:placeholder-gray-400 dark:focus:border-teal-500 dark:focus:ring-teal-500
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
          "mt-2 block w-full rounded-lg border-zinc-300 dark:bg-gray-600 dark:border-gray-500 dark:placeholder-gray-400 dark:text-white py-[7px] px-[11px]",
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
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800 dark:text-white">
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
    <p class="phx-no-feedback:hidden mt-3 flex gap-3 text-sm leading-6 text-rose-600">
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
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
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
    attr(:label, :string)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def table(assigns) do
    ~H"""
    <div id={@id} class="overflow-y-auto px-4 scm:overflow-visible sm:px-0">
      <table class="mt-11 w-[40rem] sm:w-full dark:text-gray-400">
        <thead class="text text-[0.8125rem] leading-6 text-zinc-500 dark:bg-gray-700 dark:text-gray-400">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700 dark:bg-gray-800 dark:border-gray-700 dark:text-white">
          <tr
            :for={row <- @rows}
            id={"#{@id}-#{Phoenix.Param.to_param(row)}"}
            class={["relative group hover:bg-gray-100 dark:bg-gray-800 dark:text-white", @row_class]}
          >
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div :if={i == 0}>
                <span class="absolute h-full w-4 top-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class="absolute h-full w-4 top-0 -right-4 group-hover:bg-zinc-50 sm:rounded-r-xl" />
              </div>
              <div class="block py-4 pr-6">
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, row) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="p-0 w-14">
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
    <div class="mt-14 mb-6">
      <dl
        class={"-my-4 divide-y divide-zinc-100 #{if(@type == "stripped", do: "[&>*:nth-child(odd)]:bg-gray-200 border border-gray-200 rounded-md")}"}
        ]
      >
        <div :for={item <- @item} class="flex gap-4 py-4 sm:gap-8 rounded-md">
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
    <div class="mt-16">
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
  Renders a back navigation link.

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
      <div class="rounded-t mb-0 px-4 py-3 border-0">
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
    <nav class="md:left-0 md:block md:fixed md:top-0 md:bottom-0 md:overflow-y-auto md:flex-row md:flex-nowrap md:overflow-hidden shadow-xl bg-white flex flex-wrap items-center justify-between relative md:w-64 z-10 py-4 px-6">
      <div class="md:flex-col md:items-stretch md:min-h-full md:flex-nowrap px-0 flex flex-wrap items-center w-full mx-auto">
        <.link
          patch={@home_path}
          class="md:block text-left md:pb-2 text-blueGray-600 mr-0 inline-block whitespace-nowrap text-sm uppercase font-bold p-4 px-0"
        >
          <%= @title %>
        </.link>
        <div>
          <hr class="my-4 md:min-w-full" />
          <h6 class="md:min-w-full text-blueGray-500 text-xs uppercase font-bold block pt-1 pb-4 no-underline">
            Feature
          </h6>
          <ul class="md:flex-col md:min-w-full flex flex-col list-none" id="navbar">
            <li :for={item <- @item} class="items-center">
              <.link
                navigate={item.to}
                class="text-xs uppercase py-3 font-bold block text-gray-500 hover:text-blue-400"
              >
                <i class={"fas mr-2 text-sm opacity-75 #{item.icon}"}></i>
                <%= item.title %>
              </.link>
            </li>
          </ul>
        </div>
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

  attr(:current_user, :map, required: true)

  def banner(assigns) do
    ~H"""
    <nav class="bg-white fixed w-full z-10 top-0 left-0 border-b border-gray-200 text-base font-bold dark:bg-gray-900 lg:p-3 p-2">
      <div class="flex flex-wrap items-center justify-between mx-auto">
        <a href="/" class="flex items-center">
          <.logo type="banner" class="h-8 ml-4 dark:fill-white"></.logo>
        </a>
        <div class="flex items-center md:order-2  flex-col   md:flex-row     md:space-x-2 md:w-auto">
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
            <.button id="welcome-button" type="button" phx-click={show_modal("welcome_message")}>
              Open app
            </.button>

            <button
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
            </button>
          </div>
        </div>
        <div class="hidden lg:block items-center justify-between w-full  md:w-auto">
          <ul class="flex flex-col md:flex-row md:space-x-6  text-gray-700 dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent">
            <li>
              <a href="#" class="block md:hover:text-teal-500">
                People
              </a>
            </li>
            <li>
              <a href="/orb" class="block md:hover:text-teal-500">
                Explore
              </a>
            </li>
            <li>
              <a href="#" class="flex items-center justify-between md:hover:text-teal-500   ">
                Chats
                <Heroicons.chevron_down solid class="w-4 h-4 ml-1 stroke-current dark:text-white" />
              </a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
    """
  end

  def guest_banner(assigns) do
    ~H"""
    <nav class="bg-white px-2 fixed w-full z-10 top-0 left-0 border-b border-gray-200 text-base font-bold p-2 dark:bg-gray-900">
      <div class="flex flex-wrap items-center justify-between mx-auto">
        <a href="/" class="flex items-center">
          <.logo type="banner" class="h-7 ml-4 dark:fill-white"></.logo>
        </a>
        <div class="flex gap-2">
          <.button type="button" phx-click={show_modal("welcome_message")}>
            Open app
          </.button>
          <button
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
          </button>
        </div>
      </div>
    </nav>
    """
  end

  def bottom_banner(assigns) do
    ~H"""
    <div class="hidden lg:block fixed z-10 bottom-0 w-full border border-gray-200 rounded-lg shadow bg-gray-800 dark:border-gray-700 p-2">
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
    <div class="w-full border-gray-400 border-t-2 rounded-t-2xl bg-white  lg:hidden block fixed z-10 bottom-0 px-2 py-1 dark:bg-gray-900">
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

  attr(:action, :atom)
  attr(:username, :string)
  attr(:id, :string)

  def tabs_profile(assigns) do
    ~H"""
    <div
      id={@id}
      class="w-full sticky top-0 left-0 right-0 border-b   border-gray-200 dark:bg-gray-900"
    >
      <div class="flex flex-row justify-center items-center border-b border-gray-200">
        <ul class="flex flex-wrap md:gap-x-60  gap-x-36 -mb-px font-extrabold text-sm  text-gray-500 dark:text-white">
          <li class="mr-2">
            <.link
              patch={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@username}")}
              class={[
                (@action == :show && "text-teal-600 border-teal-600 active") ||
                  "border-transparent hover:text-gray-600 hover:border-gray-300",
                "inline-flex p-4 rounded-t-lg border-b-2 GROUP"
              ]}
            >
              Posts
            </.link>
          </li>

          <li class="mr-2">
            <.link
              patch={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@username}/allies")}
              class={[
                (@action == :allies && "text-teal-600 border-teal-600 active") ||
                  "border-transparent hover:text-gray-600 hover:border-gray-300",
                "inline-flex p-4 rounded-t-lg border-b-2 GROUP"
              ]}
            >
              Allies
            </.link>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @doc """
  User profile Image and User Name
  """

  attr(:id, :string, required: true)
  attr(:user, :any)
  slot(:actions)
  slot(:information)

  def user_info_bar(assigns) do
    ~H"""
    <div id={@id} class="w-full bg-white py-2 flex items-start justify-between dark:bg-gray-900">
      <div class="flex w-full ">
        <.link
          :if={@user.username}
          navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}")}
        >
          <img
            src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
            class=" lg:h-16 lg:w-16 w-14 h-14 border-4 border-white rounded-full object-cover"
            onerror="this.src='/images/default_hand.jpg';"
          />
        </.link>
        <div>
          <h2 class="text-base font-bold text-gray-900  dark:text-white lg:text-lg ml-1">
            <%= "@#{@user.username}" %>
          </h2>
          <p class="flex items-center lg:text-base text-gray-700 dark:text-gray-400 ml-1">
            <%= render_slot(@information) %>
          </p>
        </div>
      </div>
      <div class="flex gap-2 px-2 i"><%= render_slot(@actions) %></div>
    </div>
    """
  end

  @doc """
   Orb Card View w user info bar
  """
  attr(:id, :string, required: true)
  attr(:orb, :any)
  attr(:timezone, :string)

  def scry_orb(assigns) do
    assigns =
      assign(
        assigns,
        :orb_location,
        assigns.orb |> get_in([Access.key(:payload, %{}), Access.key(:where, "-")]) ||
          assigns.orb.central_geohash |> Phos.Mainland.World.locate() ||
          "Somewhere"
      )

    ~H"""
    <div class="w-full">
      <.user_info_bar id={"#{@id}-scry-orb-#{@orb.id}"} user={@orb.initiator}>
        <:information :if={!is_nil(@orb_location)}>
          <span class="mr-1">
            <.location type="button" class="h-8 ml-4 dark:fill-white"></.location>
          </span>
          <%= @orb_location %>
        </:information>
        <:actions>
          <.chat type="banner" class="h-8 ml-4 dark:fill-white"></.chat>

          <button class="inline-block text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700  focus:outline-none  dark:focus:ring-gray-700 rounded-lg text-sm p-1.5">
            <Heroicons.ellipsis_horizontal class="lg:h=8 lg:w-8 h-6 w-6 text-black dark:text-white" />
          </button>
        </:actions>
      </.user_info_bar>

      <.media_carousel
        :if={@orb.media}
        archetype="ORB"
        uuid={@orb.id}
        path="public/banner"
        id={"#{@id}-scry-orb-#{@orb.id}"}
        orb={@orb}
        timezone={@timezone}
      />

      <.link
        :if={!@orb.media}
        id={"#{@id}-scry-orb-#{@orb.id}-link"}
        class="relative"
        navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}")}
      >
        <.orb_information id={"#{@id}-scry-orb-#{@orb.id}"} title={@orb.title} />
      </.link>

      <.orb_action :if={!@orb.media} id={"#{@id}-scry-orb-#{@orb.id}"} orb={@orb} date={@timezone} />
    </div>
    """
  end

  @spec media_carousel(map) :: Phoenix.LiveView.Rendered.t()
  @doc """
   User Post Image
   Desktop View
  """

  attr(:id, :string, required: true)
  attr(:archetype, :string, required: true)
  attr(:uuid, :string, required: true)
  attr(:path, :string)
  attr(:orb, :any)
  attr(:timezone, :string)

  def media_carousel(assigns) do
    assigns =
      assigns
      |> assign(
        :media,
        Phos.Orbject.S3.get_all!(assigns.archetype, assigns.uuid, assigns.path || "")
        |> (fn media ->
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
    <div :if={!is_nil(@media)} id={"#{@id}-carousel-wrapper"}>
      <section class="glide" id={"#{@id}-carousel"} phx-update="ignore" phx-hook="Carousel">
        <div id={"#{@id}-container"} data-glide-el="track" class="glide__track relative">
          <div class="glide__slides">
            <div :for={m <- @media} class="glide__slide">
              <div class="relative">
                <img
                  :if={(m.ext |> String.split("/") |> hd) in ["image", "application"]}
                  class="md:h-96 h-72 w-full object-cover border-gray-200 border-b-0 rounded-b-xl shadow-md dark:border-gray-700"
                  src={m.url}
                  loading="lazy"
                />
                <video
                  :if={(m.ext |> String.split("/") |> hd) in ["video"]}
                  class="w-full h-96 aspect-video hover:aspect-square object-fill border-gray-200 border-b-0 rounded-b-xl shadow-md dark:border-gray-700"
                  autoplay
                  loop
                >
                  <source src={m.url} type={m.ext} />
                </video>
              </div>
            </div>
          </div>
          <div class="absolute inset-0 flex flex-col justify-end bg-gradient-to-t from-black/60 to-black/0 w-full flex flex-col border-b-0 rounded-b-xl border-gray-200 dark:border-gray-700
          ">
            <.link
              :if={@orb.media}
              id={"#{@id}-link-#{@orb.id}"}
              class="relative"
              navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}")}
            >
              <.orb_information
                id={"#{@id}-orb-info-#{@orb.id}"}
                title={@orb.title}
                info_color="text-white"
              />
            </.link>
            <.chip emoji={[
              %{sticker: "😊", count: "20"},
              %{sticker: "❤️", count: "60"},
              %{sticker: "🥹", count: "50"},
              %{sticker: "🫠", count: "30"}
            ]} />
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
        </div>
        <div :if={length(@media) > 1} data-glide-el="controls">
          <div
            data-glide-el="controls[nav]"
            class="absolute flex space-x-3 -translate-x-1/2 bottom-2 left-1/2"
          >
            <button
              :for={count <- Enum.to_list(1..length(@media))}
              class="lg:w-3 lg:h-3 h-2 w-2 rounded-full bg-white/70 group-hover:bg-white/90 focus:ring-4 focus:ring-white group-focus:outline-none"
              data-glide-dir={"=#{count}"}
            />
          </div>

          <button
            id={"#{@id}-carousel-prev"}
            type="button"
            data-glide-dir="<"
            class="absolute top-0 left-0  flex items-center justify-center h-full px-2 cursor-pointer group focus:outline-none"
          >
            <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
              <Heroicons.chevron_left class="mt-0.5 h-6 w-6" />
            </span>
          </button>

          <button
            id={"#{@id}-carousel-next"}
            type="button"
            data-glide-dir=">"
            class="absolute top-0 right-0 flex items-center justify-center h-full px-2 cursor-pointer group focus:outline-none"
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

  @spec orb_information(map) :: Phoenix.LiveView.Rendered.t()
  @doc """
   Orb Information Box
  """
  attr(:id, :string, required: true)
  attr(:title, :string)
  attr(:info_color, :string, default: "text-gray-600")

  def orb_information(assigns) do
    ~H"""
    <p id={"#{@id}-info"} class={["lg:text-lg text-base font-bold px-2 dark:text-white", @info_color]}>
      <%= @title %>
    </p>
    """
  end

  attr(:id, :string, required: true)
  attr(:orb, :any)
  attr(:date, :string)
  attr(:main_color, :string, default: "text-gray-600")

  # TODO orb_actions wiring with data
  def orb_action(assigns) do
    ~H"""
    <div
      id={"#{@id}-actions"}
      class={["flex justify-between w-full font-bold text-base px-2", @main_color]}
    >
      <div>
        <span class="dark:text-white lg:text-lg text-base">
          <%= get_date(@orb.inserted_at, @date) %>
        </span>
      </div>
      <div class="flex flex-cols space-x-1">
        <button
          id={"#{@id}-sharebtn"}
          phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-copylink")}
          class="text-center inline-flex items-center dark:text-white"
        >
          <div id={"#{@id}-copylink"} class="hidden">
            <%= PhosWeb.Endpoint.url() <> path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}") %>
          </div>
          <.comment_share type="share" class="ml-2 fill-white"></.comment_share>
          <span class="ml-1">11</span>
        </button>
        <.link
          id={"#{@id}-scry-orb-#{@orb.id}-link"}
          class="relative"
          navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/orb/#{@orb.id}")}
        >
          <button class="text-center inline-flex items-center dark:text-white">
            <.comment_chat type="comment" class="ml-2 fill-white"></.comment_chat>
            <span class="ml-1"><%= @orb.comment_count %></span>
          </button>
        </.link>

        <button class="text-center inline-flex items-center dark:text-white">
          <.like_btn type="like" class="ml-2 fill-white"></.like_btn>
          <span class="ml-1"><span class="ml-1">22</span></span>
        </button>
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
      class="relative bg-white max-w-sm md:max-w-md md:h-auto rounded-xl shadow-lg "
    >
      <div class="flex flex-col justify-center items-center p-6 space-y-2 ">
        <img
          src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
          class=" h-16 w-16 lg:w-32 lg:h-32 border-4 border-white rounded-full object-cover"
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

  attr(:id, :string, required: true)
  attr(:navigate, :any)
  slot(:inner_block, required: true)
  attr(:user, :map, required: true)
  attr(:show_location, :boolean)
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
    <div class="relative">
      <img
        class={[
          "object-cover w-full border border-gray-200 lg:border lg:border-gray-200 lg:rounded-xl h-64 md:h-72",
          @main_height
        ]}
        src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/banner/lossless")}
        onerror="this.src='/images/default_banner.jpg';"
      />
      <div class="absolute inset-0 px-6 py-4 flex flex-col items-center bg-opacity-50">
        <p class="md:text-2xl text-lg text-white font-bold md:mb-2"><%= "@#{@user.username}" %></p>
        <div class="relative flex justify-center items-center">
          <img
            src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossless")}
            class="h-40 w-40 lg:h-48 lg:w-48 border-4 border-white rounded-full object-cover"
            onerror="this.src='/images/default_hand.jpg';"
          />
          <span class="bottom-0 right-0 inline-block absolute w-14 h-14 bg-transparent">
            <%= render_slot(@inner_block) %>
          </span>
        </div>
        <div :if={@show_location} class="flex-1 flex flex-col items-center md:mt-4 mt-2 md:px-8">
          <div class="flex items-center space-x-4">
            <div
              :for={location <- @locations}
              class="flex items-center bg-white  text-black px-4 py-2 rounded-full text-sm font-bold transition duration-100"
            >
              <.location type="button" class="ml-4 dark:fill-white"></.location>
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

  def user_information_card(assigns) do
    assigns =
      assign(
        assigns,
        :user,
        Map.from_struct(assigns.user)
      )

    ~H"""
    <div class="flex flex-col justify-between px-2 w-full ">
      <div class="gap-4 flex justify-between w-full space-y-1">
        <h2 class="flex flex-col gap-1 ">
          <span class="lg:text-2xl xl:text-3xl text-lg font-extrabold text-gray-900  dark:text-white">
            <%= @user |> get_in([:public_profile, Access.key(:public_name, "-")]) %>
          </span>
          <span class="text-base text-gray-500 font-bold dark:text-gray-400">
            <%= @user |> get_in([:public_profile, Access.key(:occupation, "-")]) %>
          </span>
        </h2>

        <div class="flex gap-6">
          <a id={"#{@id}-sharebtn"} phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-copylink")}>
            <div id={"#{@id}-copylink"} class="hidden">
              <%= PhosWeb.Endpoint.host() <>
                path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}") %>
            </div>
            <.share_btn type="banner" class="h-8 ml-4 dark:fill-white"></.share_btn>
          </a>
          <.ally_btn type="banner" class="h-8 ml-4 dark:fill-white"></.ally_btn>
        </div>
      </div>
      <div class="space-y-1">
        <p class="text-gray-700 font-medium text-base dark:text-gray-400 mt-1">
          <%= @user |> get_in([:public_profile, Access.key(:bio, "-")]) %>
        </p>

        <div>
          <span
            :for={trait <- @user |> get_in([:public_profile, Access.key(:traits, "-")])}
            class="text-gray-500 text-base font-medium dark:text-gray-400"
          >
            <span>#</span>
            <%= trait %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  attr(:user, :map, required: true)
  attr(:flex, :any, default: nil)
  attr(:id, :string, required: true)
  attr(:show_location, :boolean, default: true)

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
    <div class="flex flex-col p-4 w-full space-y-2 lg:border lg:border-gray-200 lg:rounded-xl lg:shadow-md lg:dark:bg-gray-700 dark:border-gray-700">
      <h5 class="lg:text-2xl xl:text-3xl text-lg font-extrabold text-gray-900 dark:text-white">
        <%= @user |> get_in([:public_profile, Access.key(:public_name, "-")]) %>
      </h5>
      <p class="text-gray-700 text-base font-semibold dark:text-gray-400">
        <%= @user |> get_in([:public_profile, Access.key(:occupation, "-")]) %>
      </p>
      <div class="flex gap-6 items-center justify-center">
        <a id={"#{@id}-sharebtn"} phx-click={JS.dispatch("phos:clipcopy", to: "##{@id}-copylink")}>
          <div id={"#{@id}-copylink"} class="hidden">
            <%= PhosWeb.Endpoint.host() <>
              path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@user.username}") %>
          </div>
          <.share_btn type="button" class="h-8 ml-4 dark:fill-white"></.share_btn>
        </a>
        <.ally_btn type="button" class="h-4 ml-4 dark:fill-white"></.ally_btn>
      </div>

      <div :if={@show_location} class="space-y-1">
        <div class="flex justify-evenly">
          <div
            :for={location <- @locations}
            class="flex items-center bg-white  text-black px-2 py-2 rounded-full md:text-base text-sm font-bold transition duration-100"
          >
            <.location type="button" class="h-8 ml-4 dark:fill-white"></.location>
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
            <span>#</span>
            <%= trait %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false, doc: "Default value is not to show the message")
  attr(:user, :any, default: nil, doc: "User state to create session / to redirect in app")

  def welcome_message(assigns) do
    ~H"""
    <.modal id={@id} background="bg-black/50" close_button={false} main_width="max-w-xl">
      <div
        id={"#{@id}-main-content"}
        data-selector="phos_modal_message"
        class="w-full flex flex-col items-center bg-white border border-gray-200 rounded-2xl shadow-2xl hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700 p-2"
      >
        <div class="dark:text-white">
          Welcome message
        </div>
        <p class="mt-3 font-semibold text-xl dark:text-white">Hmm...You were saying?</p>
        <p class="mt-3 w-1/2 text-center text-gray-400 dark:text-gray-400">
          Join the tribe to share your thoughts with raizzy paizzy now!
        </p>
        <div class="mt-3">
          <.button type="button">Download the Scratchbac app</.button>
        </div>
        <div :if={is_nil(@user)} class="mt-3 text-sm text-gray-500 ">
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
        <div :if={not is_nil(@user)} class="mt-3">
          <a class="hover:text-teal-400 text-base font-bold hover:underline hover:cursor-pointer dark:text-white">
            Bring me back to what I was doing!
          </a>
        </div>
      </div>
    </.modal>
    """
  end

  attr(:emoji, :any)

  def chip(assigns) do
    ~H"""
    <div class="flex gap-1 p-1">
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

  defp get_date(time, timezone) do
    time
    |> DateTime.from_naive!(timezone.timezone)
    |> Timex.shift(minutes: trunc(timezone.timezone_offset))
    |> Timex.format("{D}-{0M}-{YYYY}")
    |> elem(1)
  end
end
