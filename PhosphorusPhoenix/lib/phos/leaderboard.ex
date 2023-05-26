defmodule Phos.Leaderboard do
  import Ecto.Query
  alias Phos.Users.User
  alias Phos.Repo

  def rank_users(options) do
    # query = from u in User,
    #   preload: [:orbs, :relations],
    #   join: o in assoc(u, :orbs),
    #   join: r in assoc(u, :relations),
    #   group_by: u.id,
    #   select: %{user: u, orb_count: count(o), ally_count: count(r)},
    #   order_by: [asc: ^options.sort_by]
    query = from u in User, order_by: [asc: ^options.sort_by]
    Repo.all(query)
  end


  # orb_count =
  #   from(u in User,
  #     preload: [:orbs],
  #     join: o in assoc(u, :orbs),
  #     group_by: u.id,
  #     select: %{user: u, uid: u.id, orb_count: count(o)}
  #   )

  # ally_count =
  #   from(u in User,
  #     preload: [:relations],
  #     join: r in assoc(u, :relations),
  #     group_by: u.id,
  #     select: %{user: u, uid: u.id, ally_count: count(r)}
  #   )

  # query =
  #   from(a in ally_count,
  #     join: o in orb_count,
  #     on: a.uid == o.uid,
  #     select: %{user: a.uid, allies: a.ally_count, orbs: o.orb_count}
  #   )
  # Repo.all(ally_count)

  # def users_by_ally_count() do
  #   Repo.all()
  #   |>

  # end

  def users_by_orb_count() do
    ""
  end
end
