defmodule Telemetrex do
  defmacro span(opts, do: block_do, after: block_after) do
    metric = opts[:event]
    context = opts[:context]
    dbg()

    quote do
      :telemetry.span(unquote(metric), unquote(context), fn ->
        return_value = unquote(block_do)

        after_meta =
          if unquote(block_after) do
            return_value
            |> case do
              unquote(block_after)
            end
          else
            %{}
          end

        {return_value, after_meta}
      end)
    end
  end
end
