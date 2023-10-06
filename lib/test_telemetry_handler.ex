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
        fn event, measurements, context, _config ->
          add_event(agent_pid, [event, measurements, context])
        end,
        nil
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
end
