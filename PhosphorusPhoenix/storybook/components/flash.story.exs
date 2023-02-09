defmodule Storybook.Components.Flash do
  use PhxLiveStorybook.Story, :component

  def function, do: &PhosWeb.CoreComponents.flash/1

  def template do
    """
    <div class="relative w-full flex items-center justify-center" style="min-height:96px">
      <.lsb-variation/>
    </div>
    """
  end
  
  def variations do
    [
      %Variation{
        id: :info,
        attributes: %{
          kind: :info,
          flash: %{
            "info" => "Info text"
          }
        }
      },
      %Variation{
        id: :error,
        attributes: %{
          kind: :error,
          flash: %{
            "error" => "Danger text"
          }
        }
      },
      %Variation{
        id: :with_no_close,
        attributes: %{
          kind: :info,
          close: false,
          flash: %{
            "info" => "Info text"
          }
        }
      },
      %Variation{
        id: :with_title,
        attributes: %{
          kind: :info,
          flash: %{
            "info" => "Info text"
          },
          title: "Sample title"
        }
      }
    ]
  end
end
