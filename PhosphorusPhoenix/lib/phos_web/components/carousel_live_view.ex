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
    index = index - 1

    if index < 0 do
      index = length(media) - 1
    end

    {:noreply,
     socket
     |> assign(index: index)}
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
      <div :if={!is_nil(@media)} id={"#{@id}-carousel"}>
        <div class="h-screen w-full flex justify-center items-center">
          <img
            class="max-h-full max-w-full object-contain flex justify-center items-center"
            src={Enum.at(@media, @index).url}
            loading="lazy"
          />
        </div>
      </div>
      <div
        :if={length(@media) > 1}
        class="absolute top-0 right-0 bottom-0 flex items-center justify-center px-2"
      >
        <button
          class="p-2 rounded-full bg-gray-600 text-white"
          phx-click="previous"
          phx-target={@myself}
        >
          <Heroicons.chevron_right class="h-6 w-6" />
        </button>
      </div>
      <div
        :if={length(@media) > 1}
        class="absolute top-0 left-0 bottom-0 flex items-center justify-center px-2"
      >
        <button class="p-2 rounded-full bg-gray-600 text-white" phx-click="next" phx-target={@myself}>
          <Heroicons.chevron_left class="h-6 w-6" />
        </button>
      </div>
    </div>
    """
  end
end
