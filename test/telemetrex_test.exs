defmodule TelemetrexTest do
  use ExUnit.Case, async: true
  alias Telemetrex.TestTelemetryHandler

  defmodule Fake do
    require Telemetrex

    def test() do
      Telemetrex.span event: [:test], context: %{initial: true} do
        42
        # after
        #   42 ->
        #     %{response: "hi mom"}
        #
        #   _ ->
        #     %{response: "comment line 42"}
      end
    end

    def nested() do
      Telemetrex.span event: [:test], context: %{initial: true} do
        Telemetrex.span event: [:nested], context: %{} do
          42
        end
      after
        _ ->
          %{response: "hi mom"}
      end
    end
  end

  setup %{test: test} do
    {:ok, handler} =
      start_supervised(
        {TestTelemetryHandler,
         id: test, events: [[:test, :start], [:test, :stop], [:nested, :start], [:nested, :stop]]}
      )

    {:ok, handler: handler}
  end

  test "correct start and stop events are fired", %{handler: handler} do
    Fake.test()

    assert [[:test, :start], _measurements, _context] =
             TestTelemetryHandler.get_event(handler, 1)

    assert [[:test, :stop], _measurements, _context] =
             TestTelemetryHandler.get_event(handler, 2)
  end

  test "calling nested span blocks", %{handler: handler} do
    Fake.nested()

    assert [[:test, :start], _measurements, _context] =
             TestTelemetryHandler.get_event(handler, 1)

    assert [[:nested, :start], _measurements, _context] =
             TestTelemetryHandler.get_event(handler, 2)

    assert [[:nested, :stop], _measurements, _context] =
             TestTelemetryHandler.get_event(handler, 3)

    assert [[:test, :stop], _measurements, _context] =
             TestTelemetryHandler.get_event(handler, 4)
  end

  test "initial metadata can be passed for start event"
  test "after block adds metadata to stop event"
  test "return of do block is return of macro"

  # test "handles the do block", %{handler: handler} do
  #   assert 42 = Fake.test()
  #
  #   assert [[:test, :start], _measurements, %{initial: true}] =
  #            TestTelemetryHandler.get_event(handler, 1)
  #
  #   assert [[:test, :stop], _measurements, %{initial: true, response: "hi mom"}] =
  #            TestTelemetryHandler.get_event(handler, 2)
  # end
end
