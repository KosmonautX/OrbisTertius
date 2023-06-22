defmodule PhosWeb.UserMemoryChannelTest do
  use PhosWeb.ChannelCase

  import Phos.UsersFixtures, only: [user_fixture: 0]

  alias PhosWeb.Menshen.Auth
  alias PhosWeb.UserMemoryChannel

  setup do
    user = user_fixture()
    {:ok, socket} = PhosWeb.UserSocket.connect(%{"token" => Auth.generate_user!(user.id)},
      socket(PhosWeb.UserSocket, "user_id", %{some: "assigns"}), %{})
    {:ok, _, socket} = subscribe_and_join(socket, UserMemoryChannel, "memory:user:#{user.id}")

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})

    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "broadcast memory", %{socket: socket} do
    memory = %{}

    push(socket, "memory", {:formation, memory})
    assert_broadcast "memory_formation", ^memory
  end

  test "broadcast memory from pubsub", %{socket: _socket} do
    memory = %{}

    send(self(), {Phos.PubSub, {:memory, "event"}, memory})
    assert_receive {Phos.PubSub, {:memory, "event"}, %{}}
  end
end
