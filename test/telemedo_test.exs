defmodule TelemedoTest do
  use ExUnit.Case
  alias Telemedo.TestTelemetryHandler

  defmodule Fake do
    import Telemedo

    def test() do
      measure [:test] do
        42
      end
    end
  end

  setup %{test: test} do
    {:ok, handler} =
      start_supervised(
        {TestTelemetryHandler, id: test, events: [[:test, :start], [:test, :stop]]}
      )

    {:ok, handler: handler}
  end

  test "handles the do block", %{handler: handler} do
    assert 42 = Fake.test()

    assert [[:test, :start], _measurements, _context] = TestTelemetryHandler.get_event(handler, 1)
    assert [[:test, :stop], _measurements, _context] = TestTelemetryHandler.get_event(handler, 2)
  end
end
