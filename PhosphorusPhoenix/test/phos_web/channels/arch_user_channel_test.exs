defmodule PhosWeb.UserChannelTest do
  use PhosWeb.ChannelCase

  setup do
    {:ok, socket} = PhosWeb.UserSocket.connect(%{"token" => ~s(eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiUjNWc2pxOUNBUmZwcndPSnBzNDRrYlZjekZRMiIsInJvbGUiOiJwbGViIiwiaWF0IjoxNjQzNzQzNjAyLCJleHAiOjI4NDM3NDM2MDIsImlzcyI6IlByaW5jZXRvbiIsInN1YiI6IlNjcmF0Y2hCYWMifQ.hlhvTS37qxxqwrynoGbsHQG4gyjH5XDJfSC-zSrR6N8)},
      socket(PhosWeb.UserSocket, "user_id", %{"some": "assigns"}), %{})

    {:ok, _, socket} = socket |>
      subscribe_and_join(PhosWeb.UserChannel, "archetype:usr:R3Vsjq9CARfprwOJps44kbVczFQ2")

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to archetype:usr", %{socket: socket} do
    message = %{destination: "some destination", destination_archetype: "USR", message: "some message", subject: "some subject", subject_archetype: "ORB"}
    push(socket, "shout", message)
    assert_broadcast "shout", message
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end
end
