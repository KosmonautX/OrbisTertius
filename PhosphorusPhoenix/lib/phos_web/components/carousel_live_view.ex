defmodule PhosWeb.Components.CarouselLiveView do
  use PhosWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     assign(socket, assigns)
     |> assign_new(:index, fn -> 0 end)
     |> assign_new(:media, fn -> assigns.media end)}
  end

  @spec handle_event(<<_::32, _::_*32>>, any, %{
          :assigns => %{:index => number, :media => any, optional(any) => any},
          optional(any) => any
        }) :: {:noreply, any}
  def handle_event("previous", _, %{assigns: %{index: index, media: media}} = socket) do
    new_index = index - 1

    if new_index < 0 do
      new_index = length(media) - 1
    end

    {:noreply, socket |> assign(index: new_index)}
  end

  def handle_event("next", _, %{assigns: %{index: index, media: media}} = socket) do
    index = rem(index + 1, length(media))

    {:noreply,
     socket
     |> assign(index: index)}
  end

  attr(:media, :any)
  attr(:memory, :any)
  attr(:index, :integer)

  def render(assigns) do
    ~H"""
    <div class="relative">
      <div
        :if={!is_nil(@media)}
        id={"#{@id}-carousel"}
        class="h-screen flex justify-center items-center"
      >
        <img
          class="max-h-full max-w-full object-contain"
          src={Enum.at(@media, @index).url}
          loading="lazy"
        />
      </div>
      <div :if={length(@media) > 1}>
        <button
          type="button"
          phx-click="previous"
          phx-target={@myself}
          class="absolute inset-y-2/4	 right-0  flex items-center justify-center px-2 cursor-pointer group focus:outline-none"
        >
          <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none dark:group-focus:ring-gray-800/70 dark:bg-gray-800/30 dark:group-hover:bg-gray-800/60">
            <Heroicons.chevron_right class="h-5 w-5 dark:text-white" />
          </span>
        </button>
        <button
          type="button"
          phx-click="next"
          phx-target={@myself}
          class="absolute inset-y-2/4	 left-0  flex items-center justify-center px-2 cursor-pointer group focus:outline-none"
        >
          <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-white/30 group-hover:bg-white/50 group-focus:ring-4 group-focus:ring-white group-focus:outline-none dark:group-focus:ring-gray-800/70 dark:bg-gray-800/30 dark:group-hover:bg-gray-800/60">
            <Heroicons.chevron_left class="h-6 w-6 dark:text-white" />
          </span>
        </button>
      </div>
    </div>
    """
  end
end
