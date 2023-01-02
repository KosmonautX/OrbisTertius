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
  import Phoenix.VerifiedRoutes

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
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :confirm
  slot :cancel

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
              class="hidden relative rounded-2xl bg-white p-14 shadow-lg shadow-zinc-700/10 ring-1 ring-zinc-700/10 transition"
            >
              <div class="absolute top-6 right-5">
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
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-zinc-800">
                    <%= render_slot(@title) %>
                  </h1>
                  <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <%= render_slot(@inner_block) %>
                <div :if={@confirm != [] or @cancel != []} class="ml-6 mb-4 flex items-center gap-5">
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
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :autoshow, :boolean, default: true, doc: "whether to auto show the flash on mount"
  attr :close, :boolean, default: true, doc: "whether the flash can be closed"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("#flash")}
      role="alert"
      class={[
        "fixed hidden top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-md shadow-zinc-900/5 ring-1",
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
      <p class="font-semibold text-[0.8125rem] leading-5"><%= msg %></p>
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
  attr :for, :any, default: nil, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-8 bg-white mt-10">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
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
  attr :id, :any
  attr :name, :any
  attr :label, :string, default: nil

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :value, :any
  attr :field, :any, doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :email}"
  attr :errors, :list
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step)
  slot :inner_block

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
  attr :for, :string, default: nil
  slot :inner_block, required: true

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
  slot :inner_block, required: true

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
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
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
  attr :id, :string, required: true
  attr :row_click, :any, default: nil
  attr :rows, :list, required: true

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    ~H"""
    <div id={@id} class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="mt-11 w-[40rem] sm:w-full">
        <thead class="text-left text-[0.8125rem] leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700">
          <tr
            :for={row <- @rows}
            id={"#{@id}-#{Phoenix.Param.to_param(row)}"}
            class="relative group hover:bg-zinc-50"
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
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 sm:gap-8">
          <dt class="w-1/4 flex-none text-[0.8125rem] leading-6 text-zinc-500"><%= item.title %></dt>
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
  attr :navigate, :any, required: true
  slot :inner_block, required: true

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
  attr :title, :string, required: true
  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  attr :rest, :global,
    include: ~w(id name rel),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  def card(assigns) do
    ~H"""
    <div class={["flex flex-col min-w-0 break-words w-full mb-6 shadow-lg rounded", @class]} {@rest}>
      <div class="rounded-t mb-0 px-4 py-3 border-0">
        <h1 class="font-semibold text-lg text-gray-700"><%= @title %></h1>
      </div>
      <div class="block w-full overflow-none px-2 py-3">
        <%= render_slot(@inner_block) %>
      </div>
      <div :for={action <- @actions} class="mt-2 mb-4 flex items-center justify-between gap-6">
        <%= render_slot(action) %>
      </div>
    </div>
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
  User profile Image and User Name
  """
  attr :id, :string, required: true
  attr :img_path, :string
  slot :title
  slot :location

  def profile_upload_path(assigns) do
    ~H"""
    <div class="flex justify-between p-4 border-b md:border-none">
      <img class="rounded-full w-12 h-12 border border-gray-500" src="/images/apotheosis.png" />
      <div class="flex flex-col">
        <span class="text-base font-bold  ml-2">Sowmiya</span>
        <span class="flex items-center text-sm text-gray-500 ">
          <span>
            <Heroicons.map_pin class="mt-0.5 h-4 w-4" />
          </span>
          Chennai
        </span>
      </div>
      <button
        type="button"
        class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1 ml-auto inline-flex items-center"
      >
        <Heroicons.ellipsis_vertical class="mt-0.5 h-6 w-6" />
      </button>
    </div>
    """
  end

  @doc """
   User Post Image
   Desktop View
  """
  attr :img_post, :string

  def post_image(assigns) do
    ~H"""
    <!--<div>
      <img
        class="object-cover md:inset-0 w-[50rem] h-[30rem]"
        src="/images/thunderstorm-3440450__340.jpg"
      />
    </div>-->
    <section class="relative" id="m1" phx-hook="slider" phx-update="ignore">
      <div class="relative overflow-hidden rounded-lg duration-700 ease-in-out">
        <img
          id="m1"
          class="object-cover md:inset-0 w-[50rem] h-96"
          src="/images/IMG-20220404-WA0002.jpg"
        />
      </div>
      <button
        onclick="forward()"
        type="button"
        class="absolute top-0 left-0 z-30 flex items-center justify-center h-full px-4 cursor-pointer group focus:outline-none"
      >
        <span class="inline-flex items-center justify-center w-8 h-8 rounded-full sm:w-10 sm:h-10 bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
          <Heroicons.chevron_left class="mt-0.5 h-6 w-6" />
        </span>
      </button>
      <button
        onclick="backward()"
        type="button"
        class="absolute top-0 right-0 z-30 flex items-center justify-center h-full px-4 cursor-pointer group focus:outline-none"
      >
        <span class="inline-flex items-center justify-center w-8 h-8 rounded-full sm:w-10 sm:h-10 bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none">
          <Heroicons.chevron_right class="mt-0.5 h-6 w-6" />
        </span>
      </button>
    </section>
    """
  end

  @doc """
   User Post Information
  """

  slot :post_message

  def post_information(assigns) do
    ~H"""
    <p class="text-base text-gray-700 font-normal p-2 ml-2">
      Success is Not Final, Failure is Not Fatal: it is the Courage to Continue that Counts
      Success is Not Final, Failure is Not Fatal: it is the Courage to Continue that Counts....
    </p>
    """
  end

  @doc """
   User Post Comments And Reply
   Desktop View
  """

  attr :id, :string, required: true
  attr :comments_list, :any

  def comments_post(assigns) do
    ~H"""
    <div class="flex flex-col  md:inset-0 h-modal md:w-[34rem] md:h-[55rem] space-y-2">
      <div class="items-center justify-between mx-auto overflow-y-auto space-y-2 leading-relaxed p-2">
        <%= for comment <- @comments_list do %>
          <.comments_card comment={comment}></.comments_card>
        <% end %>
      </div>
    </div>
    """
  end

  attr :img_path, :string
  attr :comment, :any
  slot :title

  def comments_card(assigns) do
    ~H"""
    <ul class="relative border-l border-gray-200 mt-4">
      <li id="reply" class="mb-4 ml-6">
        <div class="mr-3 flex flex-cols space-x-2">
          <img class="rounded-full w-10 h-10" src={@comment.profile_image} />
          <strong><%= @comment.username %></strong>
        </div>
        <time class="block flex mt-2 text-sm font-normal leading-none text-gray-400 mb-4">
          <%= @comment.time %>
          <span class="ml-4 text-sm font-bold leading-none text-teal-700 hover:text-teal-400 hover:underline">
            Reply
          </span>
        </time>
        <p class="mb-4 text-base font-normal text-gray-500">
          <%= @comment.message %>
        </p>
      </li>
      <%= for comment <- @comment.reply_comments do %>
        <.comments_card comment={comment}></.comments_card>
      <% end %>
    </ul>
    """
  end

  attr :img_path, :string

  def input_type(assigns) do
    ~H"""
    <div class="flex p-2 gap-2 ml-2">
      <img
        class="rounded-full md:w-14 md:h-14 w-10 h-10 border border-gray-500"
        src="/images/IMG-20220404-WA0002.jpg"
      />
      <div class="flex-1 relative">
        <input
          class="block w-full p-4 text-base text-gray-900 focus:ring-black focus:outline-none  rounded-lg border border-gray-200 focus:z-10 focus:ring-4 focus:ring-gray-200"
          placeholder="Any Comments..."
          required
        />
        <button type="submit" class="absolute right-2.5 bottom-2.5 ">
          <Heroicons.paper_airplane class="h-8 w-8 mr-2" />
        </button>
      </div>
    </div>
    """
  end

  def comment_action(assigns) do
    ~H"""
    <div class="flex justify-between p-2 ml-2">
      <div class="">
        <span class="">10 Oct 2001</span>
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

  def ord_modal(assigns) do
    ~H"""
    <div class="text-base max-w-xs font-bold p-6 rounded-lg border border-gray-100 shadow-md">
      <ul class="space-y-4">
        <li>
          <a href="#" class="flex gap-4 items-center text-gray-500 hover:text-teal-600">
            <Heroicons.x_mark class="mt-0.5 h-8 w-6" />Deactivate
          </a>
        </li>
        <li>
          <a href="#" class="flex gap-4 items-center text-gray-500 hover:text-teal-600">
            <Heroicons.no_symbol class="mt-0.5 h-8 w-6" />Destroy Post
          </a>
        </li>
      </ul>
    </div>
    """
  end

  def banner(assigns) do
    ~H"""
    <nav class="border-gray-200 px-2 md:px-4 py-2.5 rounded">
      <div class="flex flex-wrap items-center justify-between mx-auto">
        <a href="/users/log_in" class="flex items-center">
          <img
            src="/images/banner_logo_white.png"
            class="h-8 mr-3 ml-4 md:h-10"
            alt="Scratchbac Logo"
          />
        </a>
        <div class="flex md:order-2">
          <button
            type="button"
            class="text-white bg-gradient-to-r from-teal-400 via-teal-500 to-teal-600 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-teal-300 font-bold rounded-lg text-sm md:text-base px-4 py-2 text-center mr-2 mb-2"
          >
            Open App
          </button>
        </div>
      </div>
    </nav>
    """
  end

  def redirect_mobile(assigns) do
    ~H"""
    <div class="relative bg-white max-w-sm md:max-w-md md:h-auto rounded-xl shadow-lg">
      <button
        type="button"
        class="absolute top-3 right-2.5 text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center"
      >
        <Heroicons.x_mark class="mt-0.5 h-8 w-6" />
        <span class="sr-only">Close modal</span>
      </button>
      <div class="text-center p-6">
        <h1 class="text-lg font-bold">Find Your Tribe</h1>
        <h3 class="mb-2 mt-2 text-base font-normal text-gray-500">
          Find Out what is happening around you today
        </h3>
      </div>
      <button
        type="button"
        class="text-white h-16 bottom-0 w-full bg-teal-600 hover:bg-teal-800 focus:ring-4 focus:outline-none focus:ring-teal-300 font-bold rounded-b-lg  text-lg inline-flex items-center text-center justify-center"
      >
        Download Scratchbac now!
      </button>
    </div>
    """
  end

  attr :current_user, :any

  def dashboard(assigns) do
    ~H"""
    <aside
      class="flex flex-col w-64  border-r border-gray-200 pt-5 pb-4 bg-gray-100"
      aria-label="Sidebar"
    >
      <div class="py-4 px-3 rounded">
        <a :if={not is_nil(@current_user.profile_image)} href="#" class="flex items-center pl-2.5 mb-5">
          <img
            src={@current_user.profile_image}
            class="mr-3 w-10 h-10 rounded-full"
          />
          <span class="self-center text-xl font-semibold whitespace-nowrap">
            <.link href={"/user/#{@current_user.username}"}> <%= @current_user.username %> </.link>
          </span>
        </a>
        <ul class="space-y-2">
          <li>
            <a
              href="#"
              class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg  hover:bg-gray-100"
            >
              <Heroicons.home class="w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900" />
              <span class="ml-3">Home</span>
            </a>
          </li>
          <li>
            <a
              href="#"
              class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg hover:bg-gray-100"
            >
              <Heroicons.plus_circle class="w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900" />
              <span class="flex-1 ml-3 whitespace-nowrap">Create</span>
            </a>
          </li>
          <li>
            <a
              href="#"
              class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg hover:bg-gray-100"
            >
              <Heroicons.map_pin class="w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900" />
              <span class="flex-1 ml-3 whitespace-nowrap">location</span>
            </a>
          </li>
          <li>
            <a
              href="#"
              class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg  hover:bg-gray-100 "
            >
              <Heroicons.chat_bubble_bottom_center class="w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900" />
              <span class="flex-1 ml-3 whitespace-nowrap">Message</span>
            </a>
          </li>
          <li>
            <a
              href="#"
              class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg hover:bg-gray-100"
            >
              <Heroicons.user class="w-6 h-6 text-gray-500 transition duration-75 group-hover:text-gray-900" />
              <span class="flex-1 ml-3 whitespace-nowrap">Profile</span>
            </a>
          </li>
        </ul>
      </div>
    </aside>
    """
  end

  def show_dropdown(to) do
    JS.show(
      to: to,
      transition:
        {"transition ease-out duration-120", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"}
    )
    |> JS.set_attribute({"aria-expanded", "true"}, to: to)
  end

  def hide_dropdown(to) do
    JS.hide(
      to: to,
      transition:
        {"transition ease-in duration-120", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
    |> JS.remove_attribute("aria-expanded", to: to)
  end

  slot :img do
    attr :src, :string
  end

  slot :title
  slot :subtitle

  slot :link do
    attr :navigate, :string
    attr :href, :string
    attr :method, :any
  end

  def dropdown(assigns) do
    ~H"""
    <!-- User account dropdown -->
    <div class="px-3 mt-6 relative inline-block text-left">
      <div>
        <button
          id={@id}
          type="button"
          class="group w-full bg-gray-100 rounded-md px-3.5 py-2 text-sm text-left font-medium text-gray-700 hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-purple-500"
          phx-click={show_dropdown("##{@id}-dropdown")}
          phx-hook="Menu"
          data-active-class="bg-gray-100"
          aria-haspopup="true"
        >
          <span class="flex w-full justify-between items-center">
            <span class="flex min-w-0 items-center justify-between space-x-3">
              <%= for img <- @img do %>
                <img
                  class="w-10 h-10 bg-gray-300 rounded-full flex-shrink-0"
                  alt=""
                  {assigns_to_attributes(img)}
                />
              <% end %>
              <span class="flex-1 flex flex-col min-w-0">
                <span class="text-gray-900 text-sm font-medium truncate">
                  <%= render_slot(@title) %>
                </span>
                <span class="text-gray-500 text-sm truncate"><%= render_slot(@subtitle) %></span>
              </span>
            </span>
            <svg
              class="flex-shrink-0 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"
                clip-rule="evenodd"
              >
              </path>
            </svg>
          </span>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="hidden z-10 mx-3 origin-top absolute right-0 left-0 mt-1 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 divide-y divide-gray-200"
        role="menu"
        aria-labelledby={@id}
      >
        <div class="py-1" role="none">
          <%= for link <- @link do %>
            <.link
              tabindex="-1"
              role="menuitem"
              class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-purple-500"
              {link}
            >
              <%= render_slot(link) %>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :navigate, :any, required: true
  attr :img_path, :string
  slot :user_name
  slot :inner_block, required: true
  attr :user, :any

  def user_profile(assigns) do
    ~H"""
    <div class="relative overflow-hidden cursor-pointer bg-white">
      <img
        class="object-cover h-80 w-full border border-gray-200 rounded-3xl shadow-lg"
        src="/images/lake-gce85e5120_1920.jpg"
        alt="Emoji"
      />
      <div class="absolute inset-0 px-6 py-4 flex flex-col items-center justify between bg-opacity-50">
        <p class="md:text-2xl text-lg text-white font-bold md:mb-4"><%= render_slot(@user_name) %></p>
        <img
          src={Phos.Orbject.S3.get!("USR", @user.id, "public/profile/lossless")}
          class="md:w-60 md:h-60 h-28 w-28 border-4 border-white rounded-full object-cover"
        />
        <button class="m-4 text-gray-900 bg-white border border-gray-300 focus:outline-none hover:bg-gray-100 focus:ring-4 focus:ring-gray-200 font-medium rounded-lg text-sm px-4 py-2 mr-2 mb-2">
          <%= render_slot(@inner_block) %>
        </button>
        <div class="flex-1 flex flex-col items-center md:mt-4 mt-2 md:px-8">
          <div class="flex items-center space-x-4">
            <%= for location <- @user.locations do %>
              <button class="flex items-center bg-white  text-black px-4 py-2 rounded-full md:text-base text-sm font-bold transition duration-100">
                <Heroicons.map_pin class="mr-2 -ml-1 md:w-6 md:h-6 w-4 h-4" />
                <span><%= location %></span>
              </button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  slot :user_role
  slot :user_bio
  slot :user_public_name
  attr :user, :any

  @spec information_card(any) :: Phoenix.LiveView.Rendered.t()
  def information_card(assigns) do
    ~H"""
    <div class="bg-white md:border md:border-gray-200 md:rounded-lg md:shadow-md font-Poppins">
      <div class="md:p-4 p-2">
        <div class="flex justify-between">
          <h5 class="md:text-3xl text-lg font-extrabold text-gray-900">
            <%= render_slot(@user_public_name) %>
          </h5>

          <div class="flex gap-4">
            <button
              type="button"
              class="text-gray-400 bg-transparent hover:bg-gray-200 p-2 rounded-lg text-sm ml-auto inline-flex items-center"
            >
              <Heroicons.share class="mt-0.5 md:h=10 md:w-10 h-6 w-6" />
            </button>
            <button class="flex items-center bg-black hover:bg-gray-700 text-white px-4 py-2 text-center rounded md:text-base text-sm font-bold transition duration-100">
              <Heroicons.plus class="mr-2 -ml-1 md:w-6 md:h-6 w-4 h-4" />
              <span>Ally</span>
            </button>
          </div>
        </div>

        <p class="md:text-lg text-gray-900 font-semibold	mb-4"><%= render_slot(@user_role) %></p>

        <a href="#" class="text-blue-600 underline text-base font-medium">
          www.scratchbac.com
        </a>

        <p class="text-gray-900 font-medium md:text-lg text-base mt-4 mb-4">
          <%= render_slot(@user_bio) %>
        </p>

        <%= for traits <- @user.traits do %>
          <span class="text-gray-500 md:text-lg text-base font-normal"><span>#</span>
            <%= traits %></span>
        <% end %>
      </div>
    </div>
    """
  end

  slot :user_role
  slot :user_bio
  slot :user_public_name
  attr :user, :any
  attr :id, :string, required: true
  attr :navigate, :any, required: true
  attr :img_path, :string
  slot :user_name
  slot :inner_block, required: true

  def user_information_card_md(assigns) do
    ~H"""
    <div class="flex flex-col items-center space-y-2 p-4">
      <h5 class="md:text-3xl text-lg font-extrabold text-gray-900 text-center">
        <%= render_slot(@user_public_name) %>
      </h5>
      <div class="flex  gap-4">
        <button
          type="button"
          class="text-gray-400 bg-transparent bg-gray-200 p-2 rounded-lg text-sm ml-auto inline-flex items-center"
        >
          <Heroicons.share class="mt-0.5 md:h=10 md:w-10 h-6 w-6" />
        </button>
        <button class="inline-flex items-center bg-yellow-400 hover:bg-gray-700 text-white px-4 py-2 text-center rounded md:text-base text-sm font-bold transition duration-100">
          Chat
        </button>
      </div>
      <div class="flex-1 flex flex-col items-center">
        <div class="flex items-center">
          <%= for location <- @user.locations do %>
            <button class="flex items-center bg-white text-gray-800 px-4 py-2 rounded-full md:text-base text-sm font-bold transition duration-100">
              <Heroicons.map_pin class="mr-2 -ml-1 w-6 h-6" />
              <span><%= location %></span>
            </button>
          <% end %>
        </div>
      </div>
      <p class="text-gray-900 font-medium text-base text-center">
        <%= render_slot(@user_bio) %>
      </p>
      <div class="items-center text-center">
        <%= for traits <- @user.traits do %>
          <span class="text-gray-500 text-base font-normal "><span>#</span>
            <%= traits %></span>
        <% end %>
      </div>
    </div>
    """
  end

  attr :user, :any
  attr :id, :string, required: true

  def explore_tag(assigns) do
    ~H"""
    <div class="items-center text-center p-2">
      <h5 class="text-2xl font-extrabold text-gray-900 text-center mb-2">
        Explore Tag
      </h5>
      <%= for traits <- @user.traits do %>
        <span class="inline-block whitespace-nowrap  align-baseline font-bold leading-none text-teal-500 rounded-full border-2 border-teal-500 text-sm px-5 py-2.5 text-center mr-2 mb-2 ">
          <span>#</span>
          <%= traits %>
        </span>
      <% end %>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :img_path, :string
  slot :title
  slot :location

  def tabs_profile(assigns) do
    ~H"""
    <div class="md:border md:border-gray-200 max-auto mt-10">
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

  def video(assigns) do
    ~H"""
    <div class="w-full mx-auto flex items-center justify-center ">
      <div class="relative">
        <video class="object-cover object-fit w-[43rem] h-[46rem]" autoplay loop muted>
          <source src="/images/WhatsApp Video 2022-12-26 at 8.32.21 AM.mp4" type="video/mp4" />
        </video>

        <div class="absolute inset-y-0 bottom-0 p-6 space-y-4 flex items-end gap-4">
          <div class="flex-1 text-white md:text-lg text-sm font-bold">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin quis turpis pretium
            Lorem ipsum dolor sit amet, consectetur adipiscing elit Lorem ipsum dolor sit amet, consectetur adipiscing elit
          </div>

          <div class="space-y-6 text-white font-extrabold text-center md:text-xl text-base">
            <div class="flex flex-col">
              <Heroicons.heart class="stroke-white md:w-10 md:h-10 w-6 h-6" />
              <span>2K</span>
            </div>

            <div class="flex flex-col">
              <Heroicons.chat_bubble_oval_left_ellipsis class="stroke-white md:w-10 md:h-10 w-6 h-6" />
              <span>226</span>
            </div>
            <div class="flex flex-col">
              <Heroicons.share class="stroke-white md:w-8 md:h-8 w-6 h-6" />
              <span>15</span>
            </div>
            <div class="flex flex-col">
              <Heroicons.window class="stroke-white md:w-14 md:h-14 w-6 h-6" />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def reply_post(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-between mx-auto w-full md:w-[43rem]">
      <div class="space-y-2 leading-relaxed p-2">
        <ul class="relative md:border-l md:border-gray-400 mt-2">
          <li id="reply" class="md:mb-4 mb-2 md:ml-6">
            <div class="mx-auto flex flex-col mt-3 text-sm leading-normal border-b border-solid border-grey-light space-y-4">
              <div class="flex justify-between md:p-2">
                <img
                  class="rounded-full w-12 h-12 border border-gray-500"
                  src="/images/apotheosis.png"
                />
                <div class="flex flex-col space-y-1">
                  <span class="font-bold">
                    <a href="#" class="text-black">tamilsowmi</a><strong>@Sowmiya</strong>
                  </span>
                  <span class="flex items-center text-sm text-gray-500 ">
                    <span>
                      <Heroicons.map_pin class="mt-0.5 h-4 w-4" />
                    </span>
                    Chennai
                  </span>

                  <div class="space-y-4">
                    <p class="text-sm md:text-base text-gray-700 font-normal">
                      Without a doubt one of the most important poems of the 20th century. “It has never lost its glamour,” Paul Muldoon observed.
                    </p>
                    <a href="#" class="text-blue-500 text-sm font-medium underline">
                      github.com/tailwindcss/ta...
                    </a>

                    <a href="#">
                      <img
                        src="/images/thunderstorm-3440450__340.jpg"
                        class="border border-solid border-grey-light rounded-sm mt-4 md:w-[43rem]"
                      />
                    </a>
                  </div>

                  <div class="flex justify-between space-x-2 p-2">
                    <div class="">
                      <span>10 Oct 2001</span>
                    </div>
                    <div class="flex flex-cols space-x-2">
                      <Heroicons.share class="mt-0.5 h-6 w-6" />
                      <Heroicons.chat_bubble_oval_left_ellipsis class="mt-0.5 h-6 w-6" />
                      <Heroicons.heart class="mt-0.5 h-6 w-6" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </li>

          <li id="reply" class="md:mb-4 mb-2 md:ml-6">
            <div class="mx-auto flex flex-col mt-3 text-sm leading-normal border-b border-solid border-grey-light space-y-4">
              <div class="flex justify-between md:p-2">
                <img
                  class="rounded-full w-12 h-12 border border-gray-500"
                  src="/images/apotheosis.png"
                />
                <div class="flex flex-col space-y-1">
                  <span class="font-bold">
                    <a href="#" class="text-black">tamilsowmi</a><strong class="text-gray-600">@Sowmiya</strong>
                  </span>
                  <span class="flex items-center text-sm text-gray-500 ">
                    <span>
                      <Heroicons.map_pin class="mt-0.5 h-4 w-4" />
                    </span>
                    Chennai
                  </span>

                  <div class="space-y-4">
                    <p class="text-sm md:text-base text-gray-700 font-normal">
                      Without a doubt one of the most important poems of the 20th century. “It has never lost its glamour,” Paul Muldoon observed. “It has never failed to be equal to both the fracture of its own era and what, alas, turned out to be the even greater fracture of the ongoing 20th century and now, it seems, the 21st century.” See also: “The Love Song of J. Alfred Prufrock.”
                    </p>
                    <a href="#" class="text-blue-500 text-sm font-medium underline">
                      github.com/tailwindcss/ta...
                    </a>

                    <a href="#">
                      <iframe
                        src="/images/WhatsApp Video 2022-12-26 at 8.32.21 AM.mp4"
                        class="border border-solid border-grey-light rounded-sm mt-4 md:w-[35rem] md:h-[30rem] h-96"
                      >
                      </iframe>
                    </a>
                  </div>

                  <div class="flex justify-between space-x-2 p-2">
                    <div class="">
                      <span>10 Oct 2001</span>
                    </div>
                    <div class="flex flex-cols space-x-2">
                      <Heroicons.share class="mt-0.5 h-6 w-6" />
                      <Heroicons.chat_bubble_oval_left_ellipsis class="mt-0.5 h-6 w-6" />
                      <Heroicons.heart class="mt-0.5 h-6 w-6" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  def multi_image(assigns) do
    ~H"""
    <div id="carouselExampleCaptions" class="carousel slide relative" data-bs-ride="carousel">
      <div class="carousel-indicators absolute right-0 bottom-0 left-0 flex justify-center p-0 mb-4">
        <button
          type="button"
          data-bs-target="#carouselExampleCaptions"
          data-bs-slide-to="0"
          class="active"
          aria-current="true"
          aria-label="Slide 1"
        >
        </button>
        <button
          type="button"
          data-bs-target="#carouselExampleCaptions"
          data-bs-slide-to="1"
          aria-label="Slide 2"
        >
        </button>
        <button
          type="button"
          data-bs-target="#carouselExampleCaptions"
          data-bs-slide-to="2"
          aria-label="Slide 3"
        >
        </button>
      </div>
      <div class="carousel-inner relative w-full overflow-hidden">
        <div class="carousel-item active relative float-left w-full">
          <img
            src="https://mdbootstrap.com/img/Photos/Slides/img%20(15).jpg"
            class="block w-full"
            alt="..."
          />
          <div class="carousel-caption hidden md:block absolute text-center">
            <h5 class="text-xl">First slide label</h5>
            <p>Some representative placeholder content for the first slide.</p>
          </div>
        </div>
        <div class="carousel-item relative float-left w-full">
          <img
            src="https://mdbootstrap.com/img/Photos/Slides/img%20(22).jpg"
            class="block w-full"
            alt="..."
          />
          <div class="carousel-caption hidden md:block absolute text-center">
            <h5 class="text-xl">Second slide label</h5>
            <p>Some representative placeholder content for the second slide.</p>
          </div>
        </div>
        <div class="carousel-item relative float-left w-full">
          <img
            src="https://mdbootstrap.com/img/Photos/Slides/img%20(23).jpg"
            class="block w-full"
            alt="..."
          />
          <div class="carousel-caption hidden md:block absolute text-center">
            <h5 class="text-xl">Third slide label</h5>
            <p>Some representative placeholder content for the third slide.</p>
          </div>
        </div>
      </div>
      <button
        class="carousel-control-prev absolute top-0 bottom-0 flex items-center justify-center p-0 text-center border-0 hover:outline-none hover:no-underline focus:outline-none focus:no-underline left-0"
        type="button"
        data-bs-target="#carouselExampleCaptions"
        data-bs-slide="prev"
      >
        <span class="carousel-control-prev-icon inline-block bg-no-repeat" aria-hidden="true"></span>
        <span class="visually-hidden">Previous</span>
      </button>
      <button
        class="carousel-control-next absolute top-0 bottom-0 flex items-center justify-center p-0 text-center border-0 hover:outline-none hover:no-underline focus:outline-none focus:no-underline right-0"
        type="button"
        data-bs-target="#carouselExampleCaptions"
        data-bs-slide="next"
      >
        <span class="carousel-control-next-icon inline-block bg-no-repeat" aria-hidden="true"></span>
        <span class="visually-hidden">Next</span>
      </button>
    </div>
    """
  end
end
