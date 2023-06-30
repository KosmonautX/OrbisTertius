defmodule PhosWeb.LocationMemoryChannelTest do
  use PhosWeb.ChannelCase

  alias PhosWeb.LocationMemoryChannel

  import Phos.UsersFixtures, only: [user_fixture: 0]

  describe "single_user" do
    setup do
      user = user_fixture()

      {:ok, socket} = PhosWeb.UserSocket.connect(%{
          "token" => PhosWeb.Menshen.Auth.generate_user!(user.id)
        }, socket(PhosWeb.UserSocket, "user_id", %{some: "assigns"}), %{})

      {:ok, _, channel} = subscribe_and_join(socket, LocationMemoryChannel, "memory:location:jurong", %{user_id: user.id})

      %{socket: socket, channel: channel, user: user}
    end

    test "handle single incoming message", %{channel: channel, user: alice} do
      ref = push(channel, "new_message", %{message: "Hello from me"})

      assert_broadcast "jurong_state", %{message: "Hello from me", user: user}
      assert alice.username == user.username
      assert_reply ref, :ok, "sent"
    end
  end

  describe "multi_user" do
    setup do
      alice = user_fixture()
      bob   = user_fixture()

      {:ok, alice_socket} = PhosWeb.UserSocket.connect(%{
          "token" => PhosWeb.Menshen.Auth.generate_user!(alice.id)
        }, socket(PhosWeb.UserSocket, "user_id", %{some: "assigns"}), %{})

      {:ok, bob_socket} = PhosWeb.UserSocket.connect(%{
          "token" => PhosWeb.Menshen.Auth.generate_user!(bob.id)
        }, socket(PhosWeb.UserSocket, "user_id", %{some: "assigns"}), %{})

      {:ok, _, alice_channel} = subscribe_and_join(alice_socket, LocationMemoryChannel, "memory:location:jurong", %{user_id: alice.id})
      {:ok, _, bob_channel} = subscribe_and_join(bob_socket, LocationMemoryChannel, "memory:location:jurong", %{user_id: bob.id})

      %{alice: alice_channel, bob: bob_channel, user_alice: alice, user_bob: bob}
    end

    test "handle single incoming message", %{alice: alice_chnl, bob: bob_chnl, user_alice: alice, user_bob: bob} do
      ref = push(alice_chnl, "new_message", %{message: "Hello from alice"})

      assert_broadcast "jurong_state", %{message: "Hello from alice"}
      assert_reply ref, :ok, "sent"

      ref = push(bob_chnl, "new_message", %{message: "Hello from bob"})

      assert_broadcast "jurong_state", %{message: "Hello from alice", reply_from: nil, user: user}
      assert user.username == alice.username
      assert_broadcast "jurong_state", %{message: "Hello from bob", reply_from: nil, user: respond}
      assert respond.username == bob.username
      assert_reply ref, :ok, "sent"
    end

    test "handle reply message", %{alice: alice_chnl, bob: bob_chnl, user_alice: alice, user_bob: bob} do
      ref = push(alice_chnl, "new_message", %{message: "This is alice speaking"})

      assert_broadcast "jurong_state", %{message: "This is alice speaking"}
      assert_reply ref, :ok, "sent"

      ref = push(bob_chnl, "new_message", %{message: "Welcome alice", reply_from: %{message: "This is alice speaking", user: alice}})

      assert_broadcast "jurong_state", %{message: "This is alice speaking", user: user}
      assert user.username == alice.username
      assert_broadcast "jurong_state", %{message: "Welcome alice", reply_from: %{user: user, message: "This is alice speaking"}, user: replier}
      assert replier.username == bob.username
      assert user.username == alice.username
      assert_reply ref, :ok, "sent"
    end
  end
end
