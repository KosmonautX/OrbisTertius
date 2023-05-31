defmodule Phos.Leaderboard do

  import Ecto.Query
  alias Phos.Users.User
  alias Phos.Repo
  alias Phos.Comments.Comment

  def list_user_counts(category \\ :orbs) do
    from(u in User,
    join: o in assoc(u, ^category),
    group_by: u.id,
    order_by: [desc: count(o)],
    select_merge: %{count: count(o)},
    limit: 20
    )
    |> Repo.all()
  end
end
