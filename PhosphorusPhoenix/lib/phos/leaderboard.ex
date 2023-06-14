defmodule Phos.Leaderboard do

  import Ecto.Query
  alias Phos.Users.User
  alias Phos.Repo
  alias Phos.Comments.Comment
  alias Phos.Action.Orb
  alias Phos.Message.Memory


  def list_user_counts(limit, page, :orbs, filter_dates) do

    from(u in User,
    join: o in assoc(u, :orbs),
    group_by: u.id,
    order_by: [desc: count(o)],
    select_merge: %{count: count(o)})
    |> between_dates(filter_dates)
    |> Repo.Paginated.all(limit: limit, page: page, aggregate: false)
  end

  def list_user_counts(limit, page, :chats, filter_dates) do

    query =
      from(m in Memory,
      join: u in User,
      on: m.user_source_id == u.id,
      group_by: [u.id, m.rel_subject_id, m.inserted_at],
      order_by: [desc: count(m)],
      distinct: [u.id, m.rel_subject_id],
      select: %{uid: u.id, r_id: m.rel_subject_id, inserted_at: m.inserted_at}
    )

    from(u in User,
      join: q in subquery(query),
      on: u.id == q.uid,
      group_by: u.id,
      order_by: [desc: count(u.id)],
      select_merge: %{count: count(u.id)}
    )
    |> between_dates(filter_dates)
    |> Repo.Paginated.all(limit: limit, page: page, aggregate: false)
  end

  def list_user_counts(limit, page, :comments, filter_dates) do

    from(u in User,
    join: c in Comment,
    on: c.initiator_id == u.id,
    group_by: u.id,
    order_by: [desc: count(c)],
    select_merge: %{count: count(c)})
    |> between_dates(filter_dates)
    |> Repo.Paginated.all(limit: limit, page: page, aggregate: false)
  end



  def list_user_counts(limit, page, :allies, filter_dates) do

    from(u in User,
    join: r in assoc(u, :relations),
    group_by: u.id,
    order_by: [desc: count(r)],
    select_merge: %{count: count(r)},
    limit: 20)
    |> between_dates(filter_dates)
    |> Repo.Paginated.all(limit: limit, page: page, aggregate: false)
  end


  def rank_orbs(limit, page, filter_dates) do

    from(o in Orb,
    preload: :initiator,
    join: c in assoc(o, :comments),
    group_by: o.id,
    order_by: [desc: count(c)],
    select_merge: %{comment_count: count(c)}
    )
    |> between_dates(filter_dates)
    |> Repo.Paginated.all(limit: limit, page: page, aggregate: false)
  end

  def beautify_date(naive_date) do
    if not is_nil(naive_date) do
    "#{naive_date.day}/#{naive_date.month}/#{naive_date.year}"
    end
  end

  defp between_dates(query, filter_dates) do
    startdt = Keyword.get(filter_dates, :startdt)
    enddt = Keyword.get(filter_dates, :enddt)

    query
    |> where([q], q.inserted_at > ^startdt)
    |> where([q], q.inserted_at < ^enddt)

  end

end
