defmodule Phos.Repo.Callbacks do
  defmacro __using__(_opts) do
    quote do
      @behaviour Phos.Repo.Callbacks

      def callback(operation, data) do
        :logger.error(%{
          label: {Phos.Repo.Callbacks, :send_callback},
          report: %{
            module: __MODULE__,
            data: data,
            operation: operation,
          }
        }, %{
          domain: [:phos, :repo],
          error_logger: %{tag: :error_msg}
        })
      end
      defoverridable callback: 2
    end
  end
end
