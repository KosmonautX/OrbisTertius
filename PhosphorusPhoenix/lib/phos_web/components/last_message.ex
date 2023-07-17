defmodule PhosWeb.Component.LastMessage do
  use PhosWeb, :live_component

  def update(%{memories: memories} = assigns, socket) do
    {:ok, assign(socket, assigns) |> assign(memories: memories)}
  end

  def get_date(time, timezone) do
    time
    |> DateTime.from_naive!(timezone.timezone)
    |> Timex.shift(minutes: trunc(timezone.timezone_offset))
    |> Timex.format("{D}-{0M}-{YYYY}")
    |> elem(1)
  end

  def get_last_memory(user) do
    user.self_relation.last_memory
  end

  def render(assigns) do
    ~H"""
    <div>
      <ul
        id="relation_memories"
        phx-update="stream"
        phx-hook="ScrollBottom"
        class={[
          if(@metadata.pagination.downstream, do: "pb-[calc(10vh)]"),
          "h-screen lg:h-[54rem] journal-scroll overflow-y-auto bg-[#F9F9F9] lg:bg-green-100 dark:bg-gray-800"
        ]}
      >
        <li :for={{dom_id, memory} <- @memories} id={dom_id}>
          <.link
            navigate={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/memories/user/#{memory.username}")}
            class=""
          >
            <div class="flex flex-wrap items-center space-x-2 px-2 py-2 transition duration-150 ease-in-out cursor-pointer hover:bg-gray-100 focus:outline-none bg-[#F9F9F9] lg:bg-white lg:dark:bg-gray-800 dark:bg-gray-900">
              <div class="flex shrink-0">
                <img
                  src={Phos.Orbject.S3.get!("USR", memory.id, "public/profile/lossless")}
                  class="w-14 h-14 rounded-full object-cover  shrink-0"
                  onerror="this.src='/images/default_hand.jpg';"
                />
              </div>
              <div class="min-w-0 flex-1">
                <div class="flex justify-between truncate">
                  <span class="font-semibold text-[#000000] dark:text-white">
                    <%= memory.username %>
                  </span>
                  <span class="font-light text-[#777986] text-[10px]">
                    <%= get_date(get_last_memory(memory).inserted_at, @date) %>
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="font-normal text-[#777986] truncate ">
                    <%= get_last_memory(memory).message %>
                  </span>
                  <span class="w-5 h-5 inline-flex items-center justify-center rounded-full text-white bg-[#00BFB2] font-semibold justify-center text-[10px] shrink-0">
                    10
                  </span>
                </div>
              </div>
            </div>
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
