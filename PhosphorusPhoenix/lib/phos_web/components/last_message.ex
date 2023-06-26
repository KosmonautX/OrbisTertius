defmodule PhosWeb.Component.LastMessage do
  use PhosWeb, :live_component

  def update(%{users: users} = assigns, socket) do
    {:ok, assign(socket, assigns) |> assign(:users, users)}
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
    <ul class="overflow-y-auto">
      <li :for={user <- @users}>
        <.link navigate={
          path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/memories/user/#{user.username}")
        }>
          <div class="flex items-center px-3 py-2 text-sm transition duration-150 ease-in-out border-b border-gray-300 cursor-pointer hover:bg-gray-100 focus:outline-none">
            <div class="relative mr-2">
              <img
                src={Phos.Orbject.S3.get!("USR", user.id, "public/profile/lossless")}
                class="w-16 h-16 border-2 border-white rounded-full object-cover"
                onerror="this.src='/images/default_hand.jpg';"
              />
              <span class="top-2 left-10 absolute w-3.5 h-3.5 bg-red-400 border-2 border-white dark:border-gray-800 rounded-full">
              </span>
            </div>
            <div class="w-full flex flex-col -mt-4">
              <div class="flex justify-between">
                <span class="block ml-2 font-semibold text-base  font-bold text-gray-900 dark:text-white mb-0 leading-normal">
                  <%= user.username %>
                </span>
                <span class="block text-gray-600"><%= get_date(get_last_memory(user).inserted_at, @date) %></span>
              </div>
              <span class="block text-gray-700 dark:text-gray-400 ml-2 mb-0 leading-relaxed">
                <%= get_last_memory(user).message %>
              </span>
            </div>
          </div>
        </.link>
      </li>
    </ul>
    """
  end
end
