defmodule Phos.TeleBot.ProfileFSM do
  defstruct [:state, :data]

  use Fsmx.Struct, transitions: %{
    "home" => "onboarding",
    "finish_profile_to_post" => "set_profile_picture",
    "profile" => ["edit_profile_name", "edit_profile_bio", "edit_profile_traits", "edit_profile_picture"],
    "*" => ["home"]
  }

  def before_transition(%{data: %{email: email}} = struct, _initial_state, "link_account") do
    {:ok, %{struct | data: %{email: email}}}
  end

  def before_transition(%{data: nil}, _initial_state, "four") do
    {:error, "cannot reach state four without data"}
  end
end
