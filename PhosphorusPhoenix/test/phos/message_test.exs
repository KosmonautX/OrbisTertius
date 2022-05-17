defmodule Phos.MessageTest do
  use Phos.DataCase

  alias Phos.Message

  describe "echoes" do
    alias Phos.Message.Echo

    import Phos.MessageFixtures

    @invalid_attrs %{destination: nil, destination_archetype: nil, message: nil, source: nil, source_archetype: nil, subject: nil, subject_archetype: nil}

    test "list_echoes/0 returns all echoes" do
      echo = echo_fixture()
      assert Message.list_echoes() == [echo]
    end

    test "get_echo!/1 returns the echo with given id" do
      echo = echo_fixture()
      assert Message.get_echo!(echo.id) == echo
    end

    test "create_echo/1 with valid data creates a echo" do
      valid_attrs = %{destination: "some destination", destination_archetype: "USR", message: "some message", source: "some source", source_archetype: "USR", subject: "some subject", subject_archetype: "ORB"}

      assert {:ok, %Echo{} = echo} = Message.create_echo(valid_attrs)
      assert echo.destination == "some destination"
      assert echo.destination_archetype == "USR"
      assert echo.message == "some message"
      assert echo.source == "some source"
      assert echo.source_archetype == "USR"
      assert echo.subject == "some subject"
      assert echo.subject_archetype == "ORB"
    end

    test "create_echo/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Message.create_echo(@invalid_attrs)
    end

    test "update_echo/2 with valid data updates the echo" do
      echo = echo_fixture()
      update_attrs = %{destination: "some updated destination", destination_archetype: "USR", message: "some updated message", source: "some updated source", source_archetype: "USR", subject: "some updated subject", subject_archetype: "ORB"}

      assert {:ok, %Echo{} = echo} = Message.update_echo(echo, update_attrs)
      assert echo.destination == "some updated destination"
      assert echo.destination_archetype == "USR"
      assert echo.message == "some updated message"
      assert echo.source == "some updated source"
      assert echo.source_archetype == "USR"
      assert echo.subject == "some updated subject"
      assert echo.subject_archetype == "ORB"
    end

    test "update_echo/2 with invalid data returns error changeset" do
      echo = echo_fixture()
      assert {:error, %Ecto.Changeset{}} = Message.update_echo(echo, @invalid_attrs)
      assert echo == Message.get_echo!(echo.id)
    end

    test "delete_echo/1 deletes the echo" do
      echo = echo_fixture()
      assert {:ok, %Echo{}} = Message.delete_echo(echo)
      assert_raise Ecto.NoResultsError, fn -> Message.get_echo!(echo.id) end
    end

    test "change_echo/1 returns a echo changeset" do
      echo = echo_fixture()
      assert %Ecto.Changeset{} = Message.change_echo(echo)
    end
  end
end
