defmodule PhosWeb.Admin.OrbLive.Index do
  use PhosWeb, :admin_view

  alias Phos.Action

  def mount(params, _session, socket) do
    orbs = get_all_active_orbs(params)
    {:ok, socket
      |> assign(:orbs, orbs)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket
      |> assign(:params, params)}
  end

  defp get_all_active_orbs(params) do
    params
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> Action.list_all_active_orbs()
  end

  # slots
  def header_item(assigns) do
    ~H"""
      <th class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left bg-gray-50 text-gray-500 border-gray-100"><%= @title %></th>
    """
  end

  def table_values(assigns) do
    ~H"""
      <%= for {entry, index} <- Enum.with_index(@entries) do %>
        <tr>
          <th class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-left flex items-center"><%= index + 1 %></th>
          <.table_column value={live_patch(entry.title, to: Routes.admin_orb_show_path(@socket, :show, entry.id))} />
          <.table_column value={entry.initiator.username} />
          <.table_column value={entry.source} />
          <.table_column value={Timex.format!(entry.inserted_at, "{D} {Mshort} {YY} {h24}:{m}")} />
        </tr>
      <% end %>
    """
  end

  def table_column(assigns) do
    ~H"""
      <td class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4">
        <%= @value %>
      </td>
    """
  end
end
