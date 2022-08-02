defmodule Phos.Admin do
  defstruct [:name, :email]

  def authenticate(password) do
    :crypto.hash(desired_algorithm(), password)
    |> Base.encode16()
    |> String.downcase()
    |> String.equivalent?(desired_password())
    |> case do
      true -> generate_token()
      _ -> {:error, "wrong password"}
    end
  end

  def verify_token(token) when  is_binary(token) and token != "" do
    case Phos.Admin.Token.verify_and_validate(token) do
      {:ok, _claims} -> {:ok, %__MODULE__{name: "admin", email: "admin@scratchbac.com"}}
      _ -> verify_token(nil)
    end
  end
  def verify_token(_), do: {:error, "Invalid token"}

  defp config do
    Application.get_env(:phos, __MODULE__, [])
    |> Keyword.put_new(:algorithm, :sha256)
  end

  defp desired_password, do: Keyword.get(config(), :password, "")
  defp desired_algorithm, do: Keyword.get(config(), :algorithm)
  defp generate_token do
    case Phos.Admin.Token.generate_and_sign() do
      {:ok, token, _claims} -> {:ok, token}
      _ -> {:error, "Error generate token"}
    end
  end
end
