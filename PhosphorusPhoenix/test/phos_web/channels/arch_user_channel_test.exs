defmodule PhosWeb.UserChannelTest do
  use PhosWeb.ChannelCase

  setup do

    user = Phos.UsersFixtures.user_fixture()

    {:ok, socket} = PhosWeb.UserSocket.connect(%{"token" => PhosWeb.Menshen.Auth.generate_user!(user.id)},
      socket(PhosWeb.UserSocket, "user_id", %{some: "assigns"}), %{})

    {:ok, _, socket} = socket |>
      subscribe_and_join(PhosWeb.UserChannel, "archetype:usr:" <> user.id)

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end
end
