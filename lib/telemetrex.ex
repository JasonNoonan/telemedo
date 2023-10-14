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

  Everything in the `do` block becomes the return value of the macro. This
  value is also passed to the optional `after` block, which can be used to set
  metadata for the ending event.

  > Similar to `:telemetry.span`, the metadata in the ending event is not
  merged with the initial context. If you want them merged, manually do so in
  the after block clause.
  """
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
