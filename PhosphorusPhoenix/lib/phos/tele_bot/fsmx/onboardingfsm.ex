defmodule Phos.TeleBot.OnboardingFSM do
  defstruct [:telegram_id, :state, path: "self/onboarding", data: %{email: ""},
    metadata: %{message_id: ""}]

  # States: "register", "linkaccount", "username"

  # use Fsmx.Struct, transitions: %{
  #   "home" => ["set_location"],
  #   "*" => ["home"]
  # }

  # def before_transition(%{data: %{location_type: location_type}} = struct, _initial_state, "set_location") do
  #   {:ok, %{struct | data: %{location_type: location_type}}}
  # end

  # def before_transition(%{data: nil}, _initial_state, "four") do
  #   {:error, "cannot reach state four without data"}
  # end
end
