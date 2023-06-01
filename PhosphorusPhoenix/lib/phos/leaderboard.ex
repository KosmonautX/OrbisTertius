defmodule Phos.Leaderboard do

  import Ecto.Query
  alias Phos.Users.User
  alias Phos.Repo
  alias Phos.Comments.Comment
  alias Phos.Action.Orb
  alias Phos.Message.Memory

  def list_user_counts(:chats) do
    query =
      from(m in Memory,
        join: u in User,
        on: m.user_source_id == u.id,
        group_by: [u.id, m.rel_subject_id],
        order_by: [desc: count(m)],
        select: %{uid: u.id, r_id: m.rel_subject_id}
      )

    from(u in User,
      join: q in subquery(query),
      on: u.id == q.uid,
      group_by: u.id,
      order_by: [desc: count(u.id)],
      select_merge: %{count: count(u.id)},
      limit: 20

    )
    |> Repo.all()
  end

  def list_user_counts(:comments) do
    from(u in User,
    join: c in Comment,
    on: c.initiator_id == u.id,
    limit: 20,
    group_by: u.id,
    order_by: [desc: count(c)],
    select_merge: %{count: count(c)})
  |> Repo.all()
  end

  def list_user_counts(:orbs) do
    from(u in User,
    join: o in assoc(u, :orbs),
    group_by: u.id,
    order_by: [desc: count(o)],
    select_merge: %{count: count(o)},
    limit: 20)
    |> Repo.all()
  end

  def list_user_counts(:relations) do
    from(u in User,
    join: o in assoc(u, :relations),
    group_by: u.id,
    order_by: [desc: count(o)],
    select_merge: %{count: count(o)},
    limit: 20)
    |> Repo.all()
  end


  def rank_orbs() do
    from(o in Orb,
    preload: :initiator,
    join: c in assoc(o, :comments),
    group_by: o.id,
    order_by: [desc: count(c)],
    select_merge: %{comment_count: count(c)}
    )
    |> Repo.all()
  end

  def beautify_date(naive_date) do
    "#{naive_date.day}-#{naive_date.month}-#{naive_date.year}"
  end


end
