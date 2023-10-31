defmodule Telemetrex do
  @moduledoc """
  Elixir wrapper for `:telemetry`.

  With the `:telemetry` library being written in a way that was both Erlang and
  Elixir friendly, the syntax can be heavy for adding telemetry to business rules.
  For example, given the following module:

  ```elixir
  defmodule MyApp.Users do
    def user_create(user_params) do
      %MyApp.User{}
      |> MyApp.User.create_changeset(users_params)
      |> MyApp.Repo.insert()
    end
  end
  ```

  If wanting to implement telemetry using `:telemetry.span`, it would result in
  the following:

  ```elixir
  defmodule MyApp.Users do
    def user_create(user_params) do
      :telemetry.span([:my_app, :user_create], %{params: user_params}, fn -> 
        %MyApp.User{}
        |> MyApp.User.create_changeset(users_params)
        |> MyApp.Repo.insert() 
        |> case do
          {:ok, %MyApp.User{} = user} = result ->
            {result, %{user: user}}
          {:error, changeset} = result ->
            {result, %{error: true, changeset: changeset}}
        end
      end)
    end
  end
  ```

  By adding telemetry with `:telemetry.span`, this operation created a lot of
  additional noise and was more intrusive to the business rules. By leveraging
  Elixir macros, much friendlier syntax can be achieved:

  ```elixir
  defmodule MyApp.Users do
    require Telemetrex

    def user_create(user_params) do
      Telemetrex.span event: [:my_app, :user_create], context: %{params: user_params} do
        %MyApp.User{}
        |> MyApp.User.create_changeset(user_params)
        |> MyApp.Repo.insert()
      after
        {:ok, %MyApp.User{} = user} ->
          %{user: user}

        {:error, changeset} ->
          %{error: true, changeset: changeset}
      end
    end
  end
  ```
  """

  @doc """
  An Elixir-friendly wrapper for `:telemetry.span`.

  ## Options

    * `event` - event prefix that will be added to start/stop events
    * `context` - initial context added to start event
    * `merge?` (default: true) - whether to merge start and stop metadata

  ```elixir
  def user_create(user_params) do
    Telemetrex.span event: [:my_app, :user_create], context: %{params: user_params} do
      %MyApp.User{}
      |> MyApp.User.create_changeset(user_params)
      |> MyApp.Repo.insert()
    after
      {:ok, %MyApp.User{} = user} ->
        %{user: user}

      {:error, changeset} ->
        %{error: true, changeset: changeset}
    end
  end
  ```

  Everything in the `do` block becomes the return value of the macro. This
  value is also passed to the optional `after` block, which can be used to set
  additional metadata for the ending event.

  > Unlike `:telemetry.span`, the metadata in the ending event is merged with
  the initial context. If you do not want them merged, set `merged?` to false.
  There are some areas where avoiding the overhead of the merge operation is
  desirable such as ecto or over high performance telemetry events.
  """
  defmacro span(opts, clauses) do
    metric = opts[:event]
    merge? = Keyword.get(opts, :merge?, true)

    context =
      Keyword.get(
        opts,
        :context,
        quote do
          %{}
        end
      )

    block_do = clauses[:do]

    block_after =
      Keyword.get(
        clauses,
        :after,
        quote do
          _do_return -> %{}
        end
      )

    quote generated: true do
      :telemetry.span(unquote(metric), unquote(context), fn ->
        return_value = unquote(block_do)

        after_meta =
          return_value
          |> case do
            unquote(block_after)
          end

        {
          return_value,
          if unquote(merge?) do
            Map.merge(unquote(context), after_meta)
          else
            after_meta
          end
        }
      end)
    end
  end

  @doc """
  Provides a human-readable duration with correct units.

  Pass the duration of the `:telemetry` span from the returned measurements to
  prettify the display for easier reading, i.e., in logs, etc.

  **Note**: the duration's time unit is native to the machine where the code is
  running when coming from `:telemetry`

  ```elixir
  iex> Telemetrex.pretty_duration(2083)
  "2µs"

  iex> Telemetrex.pretty_duration(150_000_000)
  "150ms"
  ```
  """
  def pretty_duration(duration) do
    duration = System.convert_time_unit(duration, :native, :microsecond)

    if duration > 1000 do
      duration
      |> div(1000)
      |> Integer.to_string()
      |> Kernel.<>("ms")
    else
      Integer.to_string(duration) <> "µs"
    end
  end
end
