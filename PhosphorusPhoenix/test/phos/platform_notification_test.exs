defmodule Phos.PlatformNotificationTest do
  use Phos.DataCase

  import Phos.ActionFixtures, only: [orb_fixture: 0]

  alias Phos.PlatformNotification, as: PN

  setup do
    # :ok = Ecto.Adapters.SQL.Sandbox.checkout(Phos.Repo)

    orb = orb_fixture()
    |> Phos.Repo.preload(:initiator)
    %{orb: orb, user: orb.initiator}
  end

  describe "notify/1" do
    test "return :ok when COM notification added to queue", %{user: actor} do
      msg_id = "some key" # this can get from the DB
      assert :ok = PN.notify({:email, "COM", actor.id, msg_id}, to: actor.id)
      on_exit(fn -> :timer.sleep(100) end)
    end

    test "return :ok when ORB notification added to queue", %{orb: actor} do
      msg_id = "another key" # this can get from the DB
      assert :ok = PN.notify({:email, "ORB", actor.id, msg_id}, to: actor.id)

      on_exit(fn -> :timer.sleep(100) end)

      # on_exit(fn  -> 
      #   for pid <- Task.Supervisor.children(Phos.Repo) do
      #     :timer.sleep(100)
      #     Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
      #   end
      # end)
    end

    test "return :ok when notification type not valid", %{user: actor} do
      # Producer just produce the notification
      # Validity of the notification is on another module
      msg_id = "key" # this can get from the DB
      assert :ok = PN.notify({:not_valid, "ORB", actor.id, msg_id}, to: actor.id)
      on_exit(fn -> :timer.sleep(100) end)

      # on_exit(fn  -> 
      #   for pid <- Task.Supervisor.children(Phos.Repo) do
      #     :timer.sleep(100)
      #     Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
      #   end
      # end)
    end
  end
end
