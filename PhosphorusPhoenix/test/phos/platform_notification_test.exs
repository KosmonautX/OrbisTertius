defmodule Phos.PlatformNotificationTest do
  use Phos.DataCase

  import Phos.ActionFixtures, only: [orb_fixture: 0]

  alias Phos.PlatformNotification, as: PN

  setup do
    orb = orb_fixture()
    %{orb: orb, user: orb.initiator}
  end

  describe "notify/1" do
    test "return :ok when USR notification added to queue", %{user: actor} do
      msg_id = 1 # this can get from the DB
      assert :ok = PN.notify({:email, "USR", actor.id, msg_id})
    end

    test "return :ok when ORB notification added to queue", %{orb: actor} do
      msg_id = 1 # this can get from the DB
      assert :ok = PN.notify({:email, "ORB", actor.id, msg_id})
    end

    test "return :ok when notification type not valid", %{user: actor} do
      # Producer just produce the notification
      # Validity of the notification is on another module
      msg_id = 1 # this can get from the DB
      assert :ok = PN.notify({:not_valid, "ORB", actor.id, msg_id})
    end
  end
end
