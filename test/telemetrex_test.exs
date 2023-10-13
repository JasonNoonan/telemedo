defmodule TelemetrexTest do
  use ExUnit.Case, async: true
  alias Telemetrex.TestTelemetryHandler

  defmodule Fake do
    require Telemetrex

    def test(opts \\ []) do
      context = Keyword.get(opts, :context, %{})

      Telemetrex.span event: [:test], context: context do
        42
      end
    end

    def with_after(opts \\ []) do
      context = Keyword.get(opts, :context, %{})
      after_context = Keyword.get(opts, :after_context, %{})

      Telemetrex.span event: [:test], context: context do
        42
      after
        _whatever -> after_context
      end
    end

    def nested(opts \\ []) do
      outer_context = Keyword.get(opts, :outer_context, %{})
      inner_context = Keyword.get(opts, :inner_context, %{})
      outer_after_context = Keyword.get(opts, :outer_after_context, %{})
      inner_after_context = Keyword.get(opts, :inner_after_context, %{})

      Telemetrex.span event: [:test], context: outer_context do
        Telemetrex.span event: [:nested], context: inner_context do
          42
        after
          _ ->
            inner_after_context
        end
      after
        _ ->
          outer_after_context
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
    assert 42 = Fake.test()

    assert [[:test, :start], _measurements, _context] =
             TestTelemetryHandler.get_event(handler, 1)

    assert [[:test, :stop], _measurements, _context] =
             TestTelemetryHandler.get_event(handler, 2)
  end

  test "calling nested span blocks", %{handler: handler} do
    assert 42 =
             Fake.nested(
               outer_context: %{outer: true},
               inner_context: %{inner: true},
               outer_after_context: %{outer_after: true},
               inner_after_context: %{inner_after: true}
             )

    assert [[:test, :start], _measurements, %{outer: true}] =
             TestTelemetryHandler.get_event(handler, 1)

    assert [[:nested, :start], _measurements, %{inner: true}] =
             TestTelemetryHandler.get_event(handler, 2)

    assert [[:nested, :stop], _measurements, %{inner_after: true}] =
             TestTelemetryHandler.get_event(handler, 3)

    assert [[:test, :stop], _measurements, %{outer_after: true}] =
             TestTelemetryHandler.get_event(handler, 4)
  end

  test "initial metadata can be passed for start event", %{handler: handler} do
    assert 42 = Fake.test(context: %{initial: true})

    assert [[:test, :start], _measurements, %{initial: true}] =
             TestTelemetryHandler.get_event(handler, 1)
  end

  test "after block adds metadata to stop event", %{handler: handler} do
    assert 42 = Fake.with_after(after_context: %{after: true})

    assert [[:test, :start], _measurements, _context] =
             TestTelemetryHandler.get_event(handler, 1)

    assert [[:test, :stop], _measurements, %{after: true}] =
             TestTelemetryHandler.get_event(handler, 2)
  end
end
