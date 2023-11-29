defmodule Phos.Repo do
  use Ecto.Repo,
    otp_app: :phos,
    adapter: Ecto.Adapters.Postgres

  # for purging preloads from  structs during testing
  def unpreload(structs, field, cardinality \\ :one)
  def unpreload(structs, field, cardinality) when is_list(structs) do
   Enum.map(structs, &(unpreload(&1, field, cardinality)))
  end
  def unpreload(struct, field, cardinality) do
   %{struct |
     field => %Ecto.Association.NotLoaded{
       __field__: field,
       __owner__: struct.__struct__,
       __cardinality__: cardinality
     }
   }
 end

end
