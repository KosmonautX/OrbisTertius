defmodule PhosWeb.OrbLive.Article do
  use PhosWeb, :live_view

  @impl true
  def mount(_params, _sessions, socket), do: {:ok, socket}

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, search_query: "", article: nil)}
  end

  @impl true
  def handle_event("search", %{"q" => search_query}, socket) do
    Process.send_after(self(), :search, 100)
    {:noreply, assign(socket, search_query: search_query)}
  end

  @impl true
  def handle_info(:search, %{assigns: %{search_query: query} = _assigns} = socket) do
    article = %{
      article: [
        ["If you're looking to host a BBQ party near Jurong West, you may want to check out some of these places:\n\n1. Jurong Lake Park - This park is located near Jurong West and it provides a great spot for a BBQ party. You can plan a gathering here and have a great time with your guests.\n\n2. National Parks – There are a few national parks located near the Jurong West area. These parks provide a great backdrop for an outdoor","A great place for hosting a BBQ party near Jurong West is at Kranji Reservoir Park. The park has many BBQ pits available for rent at nominal fees and also plenty of open spaces for activities. Additionally, many restaurants located nearby offer catering services and there are ample parking spots available for your convenience."],
        ["Club\n\nIn running an election in Jurong East with the support of the SB Community Club, the political party should outline a comprehensive campaign strategy to reach out to the residents of the area. This strategy may include engaging the local community through canvassing door-to-door, holding public meetings, attending local events, creating an online presence, and launching targeted digital advertisements. The party should also develop a message that resonates with the values and priorities of the community. Furthermore, developing relationships with local",
          "Club\n\nFor a party to run Jurong East with SB Community Club, they must have experience working with the local community and understand the local needs. The party should also be willing to engage in dialogue with residents and other stakeholders, such as local businesses and statutory boards, to ensure that all voices are heard. The party should also commit to working with the Community Development Councils in the area to develop suitable programmes that are tailored to the specific context of the Jurong East area. Finally, the"]
      ],
      medias: ["https://picsum.photos/200/300",
        "https://picsum.photos/200/300"],
      related_orbs: ["e0d216db-f328-42f7-bf0b-9bc239414246",
        "ae44a95e-0e5f-4da7-8707-a08cef026033"],
      title: "BBQ party near Jurong West",
      traits: ["treasurehunt", "bbq", "party", "event", "jurong", "running"]
    }
    {:noreply, assign(socket, article: article)}
  end
end
