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

  describe "memories" do
    alias Phos.Message.Memory

    import Phos.MessageFixtures

    @invalid_attrs %{media: nil, message: nil}

    test "list_memories/0 returns all memories" do
      memory = memory_fixture()
      assert Message.list_memories() == [memory]
    end

    test "get_memory!/1 returns the memory with given id" do
      memory = memory_fixture()
      assert Message.get_memory!(memory.id) == memory
    end

    test "create_memory/1 with valid data creates a memory" do
      valid_attrs = %{media: true, message: "some message"}

      assert {:ok, %Memory{} = memory} = Message.create_memory(valid_attrs)
      assert memory.media == true
      assert memory.message == "some message"
    end

    test "create_memory/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Message.create_memory(@invalid_attrs)
    end

    test "update_memory/2 with valid data updates the memory" do
      memory = memory_fixture()
      update_attrs = %{media: false, message: "some updated message"}

      assert {:ok, %Memory{} = memory} = Message.update_memory(memory, update_attrs)
      assert memory.media == false
      assert memory.message == "some updated message"
    end

    test "update_memory/2 with invalid data returns error changeset" do
      memory = memory_fixture()
      assert {:error, %Ecto.Changeset{}} = Message.update_memory(memory, @invalid_attrs)
      assert memory == Message.get_memory!(memory.id)
    end

    test "delete_memory/1 deletes the memory" do
      memory = memory_fixture()
      assert {:ok, %Memory{}} = Message.delete_memory(memory)
      assert_raise Ecto.NoResultsError, fn -> Message.get_memory!(memory.id) end
    end

    test "change_memory/1 returns a memory changeset" do
      memory = memory_fixture()
      assert %Ecto.Changeset{} = Message.change_memory(memory)
    end
  end


  describe "reveries" do
    alias Phos.Message.Reverie

    import Phos.MessageFixtures

    @invalid_attrs %{read: nil}

    test "list_reveries/0 returns all reveries" do
      reverie = reverie_fixture()
      assert Message.list_reveries() == [reverie]
    end

    test "get_reverie!/1 returns the reverie with given id" do
      reverie = reverie_fixture()
      assert Message.get_reverie!(reverie.id) == reverie
    end

    test "create_reverie/1 with valid data creates a reverie" do
      valid_attrs = %{read: ~U[2022-12-14 19:43:00Z]}

      assert {:ok, %Reverie{} = reverie} = Message.create_reverie(valid_attrs)
      assert reverie.read == ~U[2022-12-14 19:43:00Z]
    end

    test "create_reverie/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Message.create_reverie(@invalid_attrs)
    end

    test "update_reverie/2 with valid data updates the reverie" do
      reverie = reverie_fixture()
      update_attrs = %{read: ~U[2022-12-15 19:43:00Z]}

      assert {:ok, %Reverie{} = reverie} = Message.update_reverie(reverie, update_attrs)
      assert reverie.read == ~U[2022-12-15 19:43:00Z]
    end

    test "update_reverie/2 with invalid data returns error changeset" do
      reverie = reverie_fixture()
      assert {:error, %Ecto.Changeset{}} = Message.update_reverie(reverie, @invalid_attrs)
      assert reverie == Message.get_reverie!(reverie.id)
    end

    test "delete_reverie/1 deletes the reverie" do
      reverie = reverie_fixture()
      assert {:ok, %Reverie{}} = Message.delete_reverie(reverie)
      assert_raise Ecto.NoResultsError, fn -> Message.get_reverie!(reverie.id) end
    end

    test "change_reverie/1 returns a reverie changeset" do
      reverie = reverie_fixture()
      assert %Ecto.Changeset{} = Message.change_reverie(reverie)
    end
  end
end
