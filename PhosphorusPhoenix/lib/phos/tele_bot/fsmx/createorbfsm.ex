defmodule Phos.TeleBot.CreateOrbFSM do
  defstruct [:state, :data]

  use Fsmx.Struct, transitions: %{
    "home" => ["createorb"],
    "createorb" => ["createorb_media", "createorb_location", "createorb_preview"],
    "*" => ["home"]
  }

  # # createorb -> createorb_media
  # def before_transition(%{data: %{media: media}} = struct, _initial_state, "createorb_location") do
  #   {:ok, %{struct | data: %{location: location}}}
  # end

  # # createorb -> createorb_location
  # def before_transition(%{data: %{location: location}} = struct, _initial_state, "createorb_location") do
  #   {:ok, %{struct | data: %{location: location}}}
  # end

  # user has to input his inner_title, info, location to reach the "preview" state
  def before_transition(%{data: %{inner_title: inner_title, location: location}} = struct, _initial_state, "preview") do
    {:ok, struct}
  end

  def before_transition(%{data: nil}, _initial_state, "four") do
    {:error, "cannot reach state four without data"}
  end
end
