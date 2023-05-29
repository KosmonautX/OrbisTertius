defmodule Leaderboards do
  defstruct [:id, :user, :ally_count, :orb_count]
end

defmodule Phos.Leaderboard do
  defstruct [:user, :ally_count]

  import Ecto.Query
  alias Phos.Users.User
  alias Phos.Repo

  def list_users_and_counts() do
    orb_count =
      from(u in User,
        join: o in assoc(u, :orbs),
        group_by: u.id,
        order_by: [desc: count(o)],
        select: %{id: u.id, count: count(o)}
      )

    ally_count =
      from(u in User,
        join: r in assoc(u, :relations),
        group_by: u.id,
        order_by: [desc: count(r)],
        select: %{id: u.id, count: count(r)}
        )

    query =
      from(u in User,
        left_join: o in subquery(orb_count), on: u.id == o.id,
        left_join: r in subquery(ally_count), on: u.id == r.id,
        select_merge: %{id: u.id, ally_count: r.count, orb_count: o.count}
      )

    Repo.all(query)
  end

  def list_users_by_ally_count() do
    ally_count =
      from(u in User,
        join: r in assoc(u, :relations),
        group_by: u.id,
        order_by: [desc: count(r)],
        select: %Leaderboards{id: u.id, user: u, ally_count: count(r)}
        )
    Repo.all(ally_count)
  end

  def list_users_by_orb_count() do
    orb_count =
      from(u in User,
        join: o in assoc(u, :orbs),
        group_by: u.id,
        order_by: [desc: count(o)],
        select: %Leaderboards{id: u.id, user: u, orb_count: count(o)}
      )
    Repo.all(orb_count)
  end

end
