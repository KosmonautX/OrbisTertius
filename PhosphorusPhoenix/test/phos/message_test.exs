defmodule Phos.MessageTest do
  use Phos.DataCase

  alias Phos.Message

  describe "memories" do
    alias Phos.Message.Memory

    import Phos.MessageFixtures

    @invalid_attrs %{media: nil, message: nil}

    test "list_memories/0 returns all memories" do
      memory = memory_fixture()
      assert Message.list_memories() == [memory |> Phos.Repo.preload([:orb_subject, :user_source, :rel_subject])]
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
