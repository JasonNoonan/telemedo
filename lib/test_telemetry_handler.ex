defmodule Telemetrex.TestTelemetryHandler do
  use GenServer

  # Client Interface
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def add_event(handler, event) do
    GenServer.call(handler, {:add_event, event})
  end

  def get_event(handler, event_number) do
    GenServer.call(handler, {:get_event, event_number})
  end

  def attach(event, measurements, context, %{handler: handler}) do
    add_event(handler, [event, measurements, context])
  end

  # GenServer Callbacks

  @impl GenServer
  def init(opts) do
    events = opts[:events]
    id = opts[:id]

    :telemetry.attach_many(
      id,
      events,
      &__MODULE__.attach/4,
      %{handler: self()}
    )

    Process.flag(:trap_exit, true)

    {:ok, %{id: id, events: []}}
  end

  @impl GenServer
  def handle_call({:add_event, event}, _from, %{events: events} = state) do
    new_state = %{state | events: [event | events]}
    {:reply, new_state, new_state}
  end

  @impl GenServer
  def handle_call({:get_event, event_number}, _from, %{events: events} = state) do
    event =
      events
      |> Enum.reverse()
      |> Enum.at(event_number - 1)

    {:reply, event, state}
  end

  @impl GenServer
  def terminate(_reason, %{id: id}) do
    :telemetry.detach(id)
  end
end
