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

  slot(:inner_block, required: true)
  slot(:title)
  slot(:subtitle)
  slot(:confirm)
  slot(:cancel)

  def modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} class="relative z-50 hidden">
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-zinc-50/90 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="hidden relative rounded-2xl bg-white shadow-lg shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition"
            >
              <div class="absolute top-4 right-4">
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
                  <h1 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-zinc-800">
                    <%= render_slot(@title) %>
                  </h1>
                  <p :if={@subtitle != []} class="text-sm leading-4 text-zinc-600">
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <div id={"#{@id}-main"} class="p-4 w-full">
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

  attr(:rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"
  )

  slot(:inner_block, required: true)
  slot(:actions, doc: "the slot for form actions, such as a submit button")

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-4 bg-white mt-4">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-4">
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
    values: ~w(primary success warning danger)a,
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
  defp button_class(:icons), do: "bg-transparent hover:bg-gray-100"

  defp default_button_class do
    [
      "phx-submit-loading:opacity-75",
      "rounded-lg",
      "py-2",
      "px-3",
      "text-sm",
      "font-semibold",
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

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id || @name}
        name={@name}
        class={[
          input_border(@errors),
          "mt-2 block min-h-[6rem] w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
          "text-zinc-900 focus:border-zinc-400 focus:outline-none focus:ring-4 focus:ring-zinc-800/5 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5"
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
          "mt-2 block w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
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
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
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
        <h1 class="text-lg font-semibold leading-8">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="leading-6">
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
    <div id={@id} class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="mt-11 w-[40rem] sm:w-full">
        <thead class="text text-[0.8125rem] leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
          <tr
            :for={row <- @rows}
            id={"#{@id}-#{Phoenix.Param.to_param(row)}"}
            class={["relative group hover:bg-gray-100", @row_class]}
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

  attr(:navigate, :any, required: true)
  attr(:current_user, :any)

  def banner(assigns) do
    ~H"""
    <nav class="bg-white px-2 fixed w-full z-10 top-0 left-0 border-b border-gray-200 text-base font-bold p-2">
      <div class="flex flex-wrap items-center justify-between mx-auto">
        <a href="#" class="flex items-center">
          <img src="/images/banner_logo_white.png" class="h-7 ml-4" alt="" />
        </a>

        <div class="flex items-center md:order-2  flex-col   md:flex-row md:space-x-2 md:w-auto">
          <ul class="flex flex-wrap  text-center text-gray-700">
            <li :if={not is_nil(@current_user.username)} class="mr-2 hidden md:block">
              <span class="p-2 rounded-t-lg hover:text-teal-500 group">
                <.link navigate={
                  path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/user/#{@current_user.username}")
                }>
                  <Heroicons.user_circle mini class="w-8 h-8 text-gray-700 group-hover:text-teal-500" />
                </.link>
              </span>
            </li>

            <li class="mr-2 hidden md:block">
              <span class="p-2 rounded-t-lg hover:text-teal-500 group">
                <.link navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/users/settings")}>
                  <Heroicons.cog_8_tooth mini class="w-8 h-8 text-gray-700 group-hover:text-teal-500" />
                </.link>
              </span>
            </li>

            <li class="mr-2 hidden md:block">
              <span class="p-2 rounded-t-lg hover:text-teal-500 group">
                <.link
                  href={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/users/log_out")}
                  method="delete"
                >
                  <Heroicons.arrow_left_on_rectangle
                    mini
                    class="w-8 h-8 text-gray-700 group-hover:text-teal-500"
                  />
                </.link>
              </span>
            </li>
          </ul>
          <.button type="submit">Open app</.button>
        </div>

        <div class="hidden lg:block items-center justify-between w-full  md:w-auto">
          <ul class="flex flex-col md:flex-row md:space-x-6  text-gray-700">
            <li>
              <a href="#" class="block md:hover:text-teal-500">
                Pepole
              </a>
            </li>
            <li>
              <a href="#" class="block md:hover:text-teal-500">
                Explore
              </a>
            </li>
            <li>
              <a href="#" class="flex items-center justify-between md:hover:text-teal-500   ">
                Chats <Heroicons.chevron_down solid class="w-4 h-4 ml-1 stroke-current" />
              </a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
    """
  end

  def tabs_mobile(assigns) do
    ~H"""
    <div class="w-full border-gray-400 border-t-2 rounded-t-2xl bg-white lg:hidden block fixed z-10 bottom-0 px-2 py-2">
      <ul class="flex flex-wrap items-center justify-between mx-auto">
        <li>
          <a
            class="block hover:text-teal-400 text-gray-600"
            onclick="changeAtiveTab(event,'user-tab')"
          >
            <Heroicons.user_plus class="w-8 h-8" />
          </a>
        </li>
        <li>
          <a
            class="block hover:text-teal-400 text-gray-600"
            onclick="changeAtiveTab(event,'location')"
          >
            <Heroicons.map_pin class="w-8 h-8" />
          </a>
        </li>
        <li>
          <a
            class="block hover:text-teal-400 text-gray-600"
            onclick="changeAtiveTab(event,'tab-create')"
          >
            <Heroicons.plus_circle class="w-8 h-8" />
          </a>
        </li>
        <li>
          <a
            class="block hover:text-teal-400 text-gray-600 relative inline-block"
            onclick="changeAtiveTab(event,'chat')"
          >
            <Heroicons.chat_bubble_oval_left class="w-8 h-8" />
            <span class="absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white transform translate-x-1/2 -translate-y-1/2 bg-red-600 rounded-full">
              99
            </span>
          </a>
        </li>
        <li>
          <a
            class="block hover:text-teal-400 text-gray-600"
            onclick="changeAtiveTab(event,'user-profile')"
          >
            <Heroicons.plus class="w-8 h-8" />
          </a>
        </li>
      </ul>
    </div>
    """
  end

  def bottom_banner(assigns) do
    ~H"""
    <div class="hidden lg:block fixed z-20 bottom-0 right-0  px-2 py-2 w-full bg-gray-600 flex flex-col justify-items-end gap-2">
      <a
        href="#"
        class="w-full sm:w-auto bg-gray-800 hover:bg-gray-700 focus:ring-2 focus:outline-none focus:ring-gray-300 text-white rounded-lg inline-flex items-center justify-center px-4 py-2.5"
      >
        <img class="mr-3 w-7 h-7" src="/images/5761429_apple_logo_mac_mac desktop_icon (1).png" />
        <div class="text-left">
          <div class="mb-1 text-xs">Download on the</div>
          <div class="-mt-1 font-sans text-sm font-semibold">Mac App Store</div>
        </div>
      </a>
      <a
        href="#"
        class="w-full sm:w-auto bg-gray-800 hover:bg-gray-700 focus:ring-2 focus:outline-none focus:ring-gray-300 text-white rounded-lg inline-flex items-center justify-center px-4 py-2.5"
      >
        <img class="mr-3 w-7 h-7" src="/images/4373135_google_logo_logos_play_icon.png" />
        <div class="text-left">
          <div class="mb-1 text-xs">Get in on</div>
          <div class="-mt-1 font-sans text-sm font-semibold">Google Play</div>
        </div>
      </a>
    </div>
    """
  end

  @doc """
  User profile Image and User Name
  """

  attr(:id, :string, required: true)
  attr(:user, :any)
  slot(:information)
  slot(:actions)


  def user_info_bar(assigns) do
    ~H"""
        <div id={@id} class="flex items-start justify-between w-full bg-white py-2">
      <div class="flex">
        <img
          src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
          class=" lg:h-16 lg:w-16 w-14 h-14 border-4 border-white rounded-full object-cover"/>
        <div>
          <h2 class="text-base font-bold text-gray-900 -mt-1"><%= @user.username %></h2>
          <p class="flex items-center text-gray-700"><%= render_slot(@information) %></p>
        </div>
      </div>
      <div><%= render_slot(@actions) %></div>
    </div>
    """
  end

  @doc """
   User Post Image
   Desktop View
  """
  attr(:id, :string, required: true)
  attr(:img_path, :string)
  attr(:orb, :any)

  def post_image(assigns) do
    ~H"""
    <section class="relative" id={"#{@id}-media-carousell"} phx-update="ignore">
      <div class="relative overflow-hidden rounded-lg">
        <img
          id={"#{@id}-media"}
          class="object-cover md:inset-0 h-80 w-full"
          src={Phos.Orbject.S3.get!("ORB", @orb.id, "public/banner/lossless")}
        />
      </div>
      <button
        onclick="forward()"
        type="button"
        class="absolute top-0 left-0  flex items-center justify-center h-full px-4 cursor-pointer group focus:outline-none"
      >
        <span class="inline-flex items-center justify-center w-8 h-8 rounded-full sm:w-10 sm:h-10 bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
          <Heroicons.chevron_left class="mt-0.5 h-6 w-6" />
        </span>
      </button>

      <button
        onclick="backward()"
        type="button"
        class="absolute top-0 right-0 flex items-center justify-center h-full px-4 cursor-pointer group focus:outline-none"
      >
        <span class="inline-flex items-center justify-center w-8 h-8 rounded-full sm:w-10 sm:h-10 bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
          <Heroicons.chevron_right class="mt-0.5 h-6 w-6" />
        </span>
      </button>
    </section>
    """
  end

  @spec post_information(map) :: Phoenix.LiveView.Rendered.t()
  @doc """
   User Post Information
  """

  attr(:title, :any)

  def post_information(assigns) do
    ~H"""
    <p id="info" class="text-sm text-gray-900 font-normal p-2">
      <%= @title %>
    </p>
    """
  end

  def video(assigns) do
    ~H"""
    <div class="w-full flex items-center justify-center ">
      <div class="relative p-2">
        <video class="object-cover object-fit h-96 w-96" autoplay loop muted>
          <source src="/images/WhatsApp Video 2022-12-26 at 8.32.21 AM.mp4" type="video/mp4" />
        </video>

        <div class="absolute inset-y-0 bottom-0 p-4 space-y-2 flex items-end">
          <p class="flex-1 text-white text-sm font-extrabold">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin quis turpis pretium
          </p>

          <div class="space-y-4 text-white font-extrabold text-center text-sm">
            <div class="flex flex-col">
              <Heroicons.heart class="stroke-white w-8 h-8" />
              <span>2K</span>
            </div>
            <div class="flex flex-col">
              <Heroicons.chat_bubble_oval_left_ellipsis class="stroke-white w-8 h-8" />
              <span>226</span>
            </div>
            <div class="flex flex-col">
              <Heroicons.share class="stroke-white w-8 h-8" />
              <span>15</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:img_path, :string)
  attr(:user, :map, required: true)
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  def input_type(assigns) do
    ~H"""
    <div class="flex p-2 gap-2 ml-2">
      <img
        src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossless")}
        class=" h-14 w-14 border-4 border-white rounded-full object-cover"
      />
      <div class="flex-1 relative">
        <input
          class="block w-full p-4 text-base text-gray-900 focus:ring-black focus:outline-none  rounded-lg border border-gray-200 focus:ring-2 focus:ring-gray-200"
          placeholder="Any Comments..."
          required
        />
        <button type="submit" class="absolute right-2.5 bottom-2.5 ">
          <Heroicons.paper_airplane class="h-8 w-8 md:h-10 mr-2 text-teal-400 font-bold" />
        </button>
      </div>
    </div>
    """
  end

  def comment_action(assigns) do
    ~H"""
    <div id="action" class="flex justify-between p-2 w-full font-bold text-sm text-gray-600">
      <div>
        <span>10 Oct 2001</span>
      </div>
      <div class="flex flex-cols space-x-4">
        <button class="text-center inline-flex items-center">
          <Heroicons.share class="-ml-1 w-6 h-6" />15
        </button>
        <button class="text-center inline-flex items-center">
          <Heroicons.chat_bubble_oval_left_ellipsis class="-ml-1 w-6 h-6" />15
        </button>
        <button class="text-center inline-flex items-center">
          <Heroicons.heart class="-ml-1 w-6 h-6" />15
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
    <div class="relative bg-white max-w-sm md:max-w-md md:h-auto rounded-xl shadow-lg ">
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
  slot(:user_name)
  slot(:inner_block, required: true)
  attr(:user, :map, required: true)
  attr(:location, :boolean)

  @spec user_profile(map) :: Phoenix.LiveView.Rendered.t()
  def user_profile(assigns) do
    ~H"""
    <div class="relative">
      <img
        class="object-cover h-80 w-full border border-gray-200 lg:border lg:border-gray-200 lg:rounded-xl lg:shadow-md"
        src="/images/lake-gce85e5120_1920.jpg"
        alt="Emoji"
      />
      <div class="absolute inset-0 px-6 py-4 flex flex-col items-center bg-opacity-50">
        <p class="md:text-2xl text-lg text-white font-bold md:mb-4"><%= render_slot(@user_name) %></p>
        <div class="relative flex justify-center items-center">
          <img
            src={Phos.Orbject.S3.get!("USR", Map.get(@user, :id), "public/profile/lossless")}
            class=" h-48 w-48 border-4 border-white rounded-full object-cover"
          />
          <span class="bottom-0 right-0 inline-block absolute w-14 h-14 bg-transparent">
            <%= render_slot(@inner_block) %>
          </span>
        </div>
        <div
          :if={not is_nil(@location)}
          class="flex-1 flex flex-col items-center md:mt-4 mt-2 md:px-8"
        >
          <div class="flex items-center space-x-4">
            <button
              :for={location <- Map.get(@user, :locations, [])}
              class="flex items-center bg-white  text-black px-4 py-2 rounded-full md:text-base text-sm font-bold transition duration-100"
            >
              <Heroicons.map_pin class="mr-2 -ml-1 md:w-6 md:h-6 w-4 h-4" />
              <span><%= location %></span>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:user, :any)
  attr(:flex, :any, default: nil)
  attr(:id, :string, required: true)
  attr(:navigate, :any)
  attr(:location, :boolean)
  slot(:user_name)
  slot(:inner_block, required: true)

  def user_information_card(assigns) do
    ~H"""
    <div class="flex flex-col justify-between p-4 w-full">
      <div class={["gap-4", @flex]}>
        <h5 class="lg:text-2xl text-lg font-extrabold text-gray-900">
          <%= @user.public_profile.public_name %>
        </h5>
        <div class="flex gap-4">
          <.button tone={:icons}>
            <Heroicons.share class="mt-0.5 md:h=10 md:w-10 h-6 w-6 text-black" />
          </.button>
          <.button class="flex items-center p-0 items-start space-y-1">
            <Heroicons.plus class="mr-2 -ml-1 md:w-6 md:h-6 w-4 h-4 " />
            <span>Ally</span>
          </.button>
        </div>
      </div>

      <div class="space-y-1">
        <div :if={not is_nil(@location)}>
          <div class="flex justify-center	">
            <%= for location <- @user.locations do %>
              <button class="flex   bg-white text-gray-800 px-4 py-2 rounded-full text-base font-bold">
                <Heroicons.map_pin class="mr-2 -ml-1 w-6 h-6" />
                <span><%= location %></span>
              </button>
            <% end %>
          </div>
        </div>

        <p class="md:text-lg text-gray-900 text-base font-semibold">
          <%= @user.public_profile.occupation %>
        </p>
        <p class="text-gray-900 font-medium text-base">
          <%= @user.public_profile.bio %>
        </p>

        <div>
          <%= for traits <- @user.traits do %>
            <span class="text-gray-500 text-base font-medium"><span>#</span>
              <%= traits %></span>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def tabs_profile(assigns) do
    ~H"""
    <div class="lg:border lg:border-gray-200 rounded-t-3xl mt-10 w-full z-20 top-0 left-0 border-b border-gray-200">
      <div class="flex justify-center items-center border-b border-gray-200">
        <ul class="flex flex-wrap md:gap-80 gap-20 -mb-px md:text-lg font-extrabold text-sm font-medium text-gray-500">
          <li class="mr-2">
            <a
              href="#"
              class="inline-flex p-4 text-blue-600 rounded-t-lg border-b-2 border-blue-600 active group"
            >
              Posts
            </a>
          </li>

          <li class="mr-2">
            <a
              href="#"
              class="inline-flex p-4 rounded-t-lg border-b-2 border-transparent hover:text-gray-600 hover:border-gray-300 group"
              md:w-8
              md:h-8
            >
              Allies
            </a>
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
