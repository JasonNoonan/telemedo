defmodule Telemedo do
  defmacro measure(metric, do: block) do
    quote do
      :telemetry.span(unquote(metric), %{}, fn ->
        return_value = unquote(block)
        {return_value, %{}}
      end)
    end
  end
end
