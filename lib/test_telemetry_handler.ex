defmodule Telemedo.TestTelemetryHandler do
  use Agent

  def start_link(opts) do
    events = opts[:events]
    id = opts[:id]

    Agent.start_link(fn ->
      agent_pid = self()

      :telemetry.attach_many(
        id,
        events,
        &__MODULE__.attach/4,
        %{agent: agent_pid}
      )

      []
    end)
  end

  def add_event(agent, event) do
    Agent.update(agent, fn events -> [event | events] end)
  end

  def get_event(handler, event_number) do
    Agent.get(handler, fn events ->
      events
      |> Enum.reverse()
      |> Enum.at(event_number - 1)
    end)
  end

  def attach(event, measurements, context, %{agent: agent}) do
    add_event(agent, [event, measurements, context])
  end
end
