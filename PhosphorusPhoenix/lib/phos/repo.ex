defmodule Phos.Repo do
  use Ecto.Repo,
    otp_app: :phos,
    adapter: Ecto.Adapters.Postgres

    defoverridable insert: 2,
                   insert!: 2
                   # update: 2,
                   # update!: 2
  
  def insert(struct_or_changeset, opts) do
    super(struct_or_changeset, opts)
    |> tap(&prepare_callback(&1, :insert))
  end

  def insert!(struct_or_changeset, opts) do
    super(struct_or_changeset, opts)
    |> tap(&prepare_callback(&1, :insert!))
  end

  ## future rescinding notification upon deactivate etc

  # def update(changeset, opts) do
  #   super(changeset, opts)
  #   |> prepare_callback(:update)
  # end

  # def update!(changeset, opts) do
  #   super(changeset, opts)
  #   |> prepare_callback(:update!)
  # end

  defp prepare_callback(data, operation) when operation in [:insert!, :update!], do: define_callback(data, operation)
  defp prepare_callback({:ok, data}, operation), do: define_callback(data, operation)
  defp prepare_callback(err, _operation), do: err

  defp define_callback(%{__struct__: module} = data, operation) do
    callback_module =
      to_string(module)
      |> String.split(".")
      |> List.last()
      |> to_atom()


    callback_module
    |> Code.ensure_loaded()
    |> case do
      {:module, module} -> 
        spawn(fn -> apply(module, :callback, [operation, data]) end)
        return_data(data, operation)
      {:error, :nofile} -> return_data(data, operation)
    end
  end

  defp define_callback(data, _operation), do: data

  defp to_atom(string_module) do
    module = "Elixir.Phos.Repo.Callbacks.#{string_module}"
    try do
      String.to_existing_atom(module)
    rescue ArgumentError ->
      String.to_atom(module)
    end
  end

  defp return_data(data, operation) do
    case String.ends_with?("#{operation}", "!") do
      true -> data
      _ -> {:ok, data}
    end
  end
end
