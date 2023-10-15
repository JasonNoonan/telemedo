defmodule TelemetrexTest do
  use ExUnit.Case, async: true

  doctest Telemetrex

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

    def no_context() do
      Telemetrex.span event: [:test] do
        :no_context
      end
    end

    def no_merge(opts) do
      context = Keyword.get(opts, :context, %{})
      after_context = Keyword.get(opts, :after_context, %{})

      Telemetrex.span event: [:test], context: context, merge?: false do
        :no_merge
      after
        _whatever -> after_context
      end
    end
  end

  setup do
    telemetry_ref =
      :telemetry_test.attach_event_handlers(self(), [
        [:test, :start],
        [:test, :stop],
        [:nested, :start],
        [:nested, :stop]
      ])

    {:ok, %{telemetry_ref: telemetry_ref}}
  end

  test "correct start and stop events are fired", %{telemetry_ref: telemetry_ref} do
    assert 42 = Fake.test()

    assert_received {[:test, :start], ^telemetry_ref, _measurements, _context}
    assert_received {[:test, :stop], ^telemetry_ref, _measurements, _context}
  end

  test "calling nested span blocks", %{telemetry_ref: telemetry_ref} do
    assert 42 =
             Fake.nested(
               outer_context: %{outer: true},
               inner_context: %{inner: true},
               outer_after_context: %{outer_after: true},
               inner_after_context: %{inner_after: true}
             )

    assert_received {[:test, :start], ^telemetry_ref, _measurements, %{outer: true}}
    assert_received {[:nested, :start], ^telemetry_ref, _measurements, %{inner: true}}
    assert_received {[:nested, :stop], ^telemetry_ref, _measurements, %{inner_after: true}}
    assert_received {[:test, :stop], ^telemetry_ref, _measurements, %{outer_after: true}}
  end

  test "initial metadata can be passed for start event", %{telemetry_ref: telemetry_ref} do
    assert 42 = Fake.test(context: %{initial: true})
    assert_received {[:test, :start], ^telemetry_ref, _measurements, %{initial: true}}

    assert :no_context = Fake.no_context()
    assert_received {[:test, :start], ^telemetry_ref, _measurements, %{}}
  end

  test "after block adds metadata to stop event", %{telemetry_ref: telemetry_ref} do
    opts = [context: %{initial: true}, after_context: %{after: true}]
    assert 42 = Fake.with_after(opts)

    assert_received {[:test, :start], ^telemetry_ref, _measurements, %{initial: true}}
    assert_received {[:test, :stop], ^telemetry_ref, _measurements, %{initial: true, after: true}}

    # merge can be opted out of
    assert :no_merge = Fake.no_merge(opts)

    assert_received {[:test, :start], ^telemetry_ref, _measurements, %{initial: true}}
    assert_received {[:test, :stop], ^telemetry_ref, _measurements, metadata}
    refute Map.has_key?(metadata, :initial)
  end
end
