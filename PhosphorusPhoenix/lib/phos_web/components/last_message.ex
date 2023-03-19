defmodule PhosWeb.Component.LastMessage do
  use PhosWeb, :live_component

  def update(%{memories: memories} = assigns, socket) do
    mems = memories
      |> Enum.reverse()
      |> Enum.uniq_by(&(&1.rel_subject_id))
      |> Enum.filter(&(!is_nil(&1.rel_subject_id)))

    {:ok, assign(socket, assigns) |> assign(:memories, mems)}
  end

  defp get_date(time, timezone) do
    time
    |> DateTime.from_naive!(timezone.timezone)
    |> Timex.shift(minutes: trunc(timezone.timezone_offset))
    |> Timex.format("{D}-{0M}-{YYYY}")
    |> elem(1)
  end

  defp get_profile(%{initiator_id: user_id} = root, %{id: id} = _current_user) when user_id == id do
    root.acceptor_id
  end
  defp get_profile(%{initiator_id: user_id}, _current_user), do: user_id

  defp get_username(%{initiator_id: user_id} = root, %{id: id} = _current_user) when user_id == id do
    Phos.Users.get_user!(root.acceptor_id).username
  end
  defp get_username(%{initiator_id: user_id}, _current_user) do
    Phos.Users.get_user!(user_id).username
  end

  def render(assigns) do
    ~H"""
    <ul class="overflow-y-auto">
      <li :for={memory <- @memories}>
        <.link navigate={
          path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/memories/user/#{get_username(memory.rel_subject, @current_user)}")
        }>
          <div class="flex items-center px-3 py-2 text-sm transition duration-150 ease-in-out border-b border-gray-300 cursor-pointer hover:bg-gray-100 focus:outline-none">
            <div class="relative mr-2">
              <img
                src={Phos.Orbject.S3.get!("USR", get_profile(memory.rel_subject, @current_user), "public/profile/lossless")}
                class="w-16 h-16 border-2 border-white rounded-full object-cover"
                onerror="this.src='/images/default_hand.jpg';"
              />
              <span class="top-2 left-10 absolute w-3.5 h-3.5 bg-red-400 border-2 border-white dark:border-gray-800 rounded-full">
              </span>
            </div>
            <div class="w-full flex flex-col -mt-4">
              <div class="flex justify-between">
                <span class="block ml-2 font-semibold text-base  font-bold text-gray-900 dark:text-white mb-0 leading-normal">
                  <%= get_username(memory.rel_subject, @current_user) %>
                </span>
                <span class="block text-gray-600"><%= get_date(memory.inserted_at, @date) %></span>
              </div>
              <span class="block text-gray-700 dark:text-gray-400 ml-2 mb-0 leading-relaxed">
                <%= memory.message %>
              </span>
            </div>
          </div>
        </.link>
      </li>
    </ul>
    """
  end
end
