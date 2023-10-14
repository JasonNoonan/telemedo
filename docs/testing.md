# Testing Guidelines

As Telemetrex is an Elixir-friendly wrapper around `:telemetry`, it is advised to follow `:telemetry` best practices with regards to testing as well.

[:telemetry_test](https://hexdocs.pm/telemetry/telemetry_test.html)

Given the following module implementing `Telemetrex.span`:

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

Here's how we could test the firing of the events:

```elixir
test "test events are fired" do
  # Arrange
  ref = :telemetry_test.attach_event_handlers(self(), [[:my_app, :user_create, :start], [:my_app, :user_create, :start]])

  # Act
  MyApp.Users.user_create(%{first_name: "thanks", last_name: "telemetry"})

  # Assert
  assert_received {[:my_app, :user_create, :start], ^ref, %{measurement: _}, %{meta: _}}
  assert_received {[:my_app, :user_create, :stop], ^ref, %{measurement: _}, %{meta: _}}
end
```
