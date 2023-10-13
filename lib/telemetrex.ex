defmodule Telemetrex do
  defmacro span(opts, clauses) do
    metric = opts[:event]
    context = opts[:context]
    block_do = clauses[:do]

    block_after =
      Keyword.get(
        clauses,
        :after,
        quote do
          _do_return -> %{}
        end
      )

    quote do
      :telemetry.span(unquote(metric), unquote(context), fn ->
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
