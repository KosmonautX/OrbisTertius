defmodule PhosWeb.Components.ScrollAlly do
  use PhosWeb, :live_component

  defp random_id, do: Enum.random(1..1_000_000)

  def render(assigns) do
    ~H"""
    <div>
      <div id="infinite-scroll-body" phx-update="append" class="overflow-x">
        <.user_info_bar :for={ally <- @ally_list} :if={!is_nil(Map.get(ally, :username))} id={"user-#{random_id()}-infobar"} user={ally}>
          <:information>
            <%= ally |> get_in([Access.key(:public_profile, %{}), Access.key(:occupation, "-")])%>
          </:information>
          <:actions>
          <svg width="81" height="45" viewBox="0 0 81 45" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect width="81" height="45" rx="15" fill="#00BFB2"/>
          <path d="M24.336 18.224V21.328H21.312V23.28H24.336V26.384H26.448V23.28H29.472V21.328H26.448V18.224H24.336ZM39.4693 28H41.8373L37.8213 16.816H35.2133L31.1973 28H33.5493L34.2853 25.872H38.7333L39.4693 28ZM38.1253 24.08H34.8932L36.5093 19.408L38.1253 24.08ZM43.3384 28H45.5784V16.16H43.3384V28ZM47.7915 28H50.0315V16.16H47.7915V28ZM56.0206 25.328L53.7326 19.136H51.2206L54.7726 27.776L52.8526 32.192H55.2366L60.7246 19.136H58.3406L56.0206 25.328Z" fill="white"/>
          </svg>
          </:actions>
        </.user_info_bar>
      </div>
      <div id="infinite-scroll-marker" phx-hook="Scroll" data-page={@page} />
    </div>
    """
  end
end
