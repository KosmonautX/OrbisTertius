defmodule Phos.Repo do
  use Ecto.Repo,
    otp_app: :phos,
    adapter: Ecto.Adapters.Postgres

  #   defoverridable insert: 2,
  #                  insert!: 2
  #                  # update: 2,
  #                  # update!: 2

  # def insert(struct_or_changeset, opts) do
  #   super(struct_or_changeset, opts)
  #   |> tap(&prepare_callback(&1, :insert))
  # end

  # def insert!(struct_or_changeset, opts) do
  #   super(struct_or_changeset, opts)
  #   |> tap(&prepare_callback(&1, :insert!))
  # end

  ## future rescinding notification upon deactivate etc

  # def update(changeset, opts) do
  #   super(changeset, opts)
  #   |> prepare_callback(:update)
  # end

  # def update!(changeset, opts) do
  #   super(changeset, opts)
  #   |> prepare_callback(:update!)
  # end

  # defp prepare_callback(data, operation) when operation in [:insert!, :update!], do: define_callback(data, operation)
  # defp prepare_callback({:ok, data}, operation) when operation in [:insert, :update], do: define_callback(data, operation)
  # defp prepare_callback(err, _operation), do: :ok

  # defp define_callback(%{__struct__: module} = data, operation) do
  #   callback_module =
  #     to_string(module)
  #     |> String.split(".")
  #     |> List.last()
  #     |> to_atom()


  #   callback_module
  #   |> Code.ensure_loaded()
  #   |> case do
  #     {:module, module} ->
  #       spawn(fn -> apply(module, :callback, [operation, data]) end)
  #       :ok
  #     {:error, :nofile} -> :ok
  #   end
  # end

  # defp define_callback(data, _operation), do: data

  # defp to_atom(string_module) do
  #   module = "Elixir.Phos.Repo.Callbacks.#{string_module}"
  #   try do
  #     String.to_existing_atom(module)
  #   rescue ArgumentError ->
  #     String.to_atom(module)
  #   end
  # end
end
