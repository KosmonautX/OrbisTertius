defmodule PhosWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use PhosWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint PhosWeb.Endpoint

      use PhosWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import PhosWeb.ConnCase

      alias PhosWeb.Router

    end
  end

  setup tags do

    # start_owner uses a separate process to own the connection
    # the owner of the connection will be a separate process (from the test process)
    # that then we will terminate

    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Phos.Repo, shared: not tags[:async])

    on_exit(fn ->

      # does timer here make it more reliable(?)
      :timer.sleep(100)

      # this process will terminate after the dangling presence processes are DOWN
      for pid <- PhosWeb.Presence.fetchers_pids() do
        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, _, _, _}, 1000
      end

      # assert child processes to task supervisor such as notifications are down
      for pid <- Task.Supervisor.children(Phos.TaskSupervisor) do
        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, _, _, _}, 1000
      end
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Phos.UsersFixtures.user_fixture()

    %{conn: log_in_user(conn, user), user: user}
  end

  def inject_user_token(%{conn: conn}) do
    user = Phos.UsersFixtures.user_fixture()
    {:ok, token, _claims}= PhosWeb.Menshen.Auth.generate_user(user.id)
    %{conn: conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_req_header("authorization",
      token), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Phos.Users.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
