defmodule PhosWeb.Component.LastMessage do
  use PhosWeb, :live_component
  def update(%{memories: memories} = assigns, socket) do
    {:ok, assign(socket, assigns) |> assign(memories: memories)}
  end

  defp get_date(time, timezone) do
    time
    |> DateTime.from_naive!(timezone.timezone)
    |> Timex.shift(minutes: trunc(timezone.timezone_offset))
    |> Timex.format("{D}-{0M}-{YYYY}")
    |> elem(1)
  end

  defp get_last_memory(user) do
    user.self_relation.last_memory
  end

  def render(assigns) do
    ~H"""
      <ul
        id="relation_memories"
        phx-update="stream"
        phx-hook="ScrollBottom"
        class={[
          if(@metadata.pagination.downstream, do: "pb-[calc(10vh)]"),
          "lg:h-[49rem] h-screen journal-scroll overflow-y-auto bg-[#F9F9F9] lg:bg-white dark:bg-gray-800"
        ]}
        >
       <li :for={{dom_id, memory} <- @memories} id={dom_id}>
        <.link patch={path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/memories/user/#{memory.username}")}>
         <div class="flex items-center lg:px-3 lg:py-2 md:px-10 px-2 py-3 transition duration-150 ease-in-out border-b border-zinc-300 dark:border-none  cursor-pointer hover:bg-gray-100 focus:outline-none bg-[#F9F9F9] lg:bg-white lg:dark:bg-gray-800 dark:bg-gray-900">
           <div class="relative shrink-0">
             <img src={Phos.Orbject.S3.get!("USR", memory.id, "public/profile/lossless")}
               class="w-14 h-14 rounded-full object-cover" onerror="this.src='/images/default_hand.jpg';"/>
           </div>
           <div class="w-full flex flex-col text-sm ml-2">
             <div class="flex justify-between">
               <span class="font-semibold text-[#000000] dark:text-white"><%= memory.username %></span>
               <span class="font-light text-[#777986]"><%= get_date(get_last_memory(memory).inserted_at, @date) %></span>
             </div>
             <div class="flex justify-between">
               <span class="font-normal text-[#777986] truncate lg:w-80 w-60 md:w-96"><%= get_last_memory(memory).message %></span>
               <span class="w-6 h-6 inline-flex items-center rounded-full text-white bg-[#00BFB2] font-semibold justify-center text-xs">10</span>
             </div>
           </div>
         </div>
        </.link>
       </li>
      </ul>
    """
  end
end
