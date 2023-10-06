defmodule Telemedo do
  defmacro measure(metric, do: block_do, after: block_after) do
    quote do
      :telemetry.span(unquote(metric), %{}, fn ->
        return_value = unquote(block_do)

        after_meta =
          return_value
          |> case do
            unquote(block_after)
          end

        {return_value, after_meta}
      end)
    end
  end
end
