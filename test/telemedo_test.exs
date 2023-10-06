defmodule TelemedoTest do
  use ExUnit.Case

  defmodule Fake do
    import Telemedo

    def test() do
      measure [:test] do
        42
      end
    end
  end

  setup %{test: test} do
    {:ok, pid} = start_supervised({Agent, fn -> [] end})
    attach_metric(test, pid)
    {:ok, agent: pid}
  end

  test "handles the do block", %{agent: agent} do
    assert 42 = Fake.test()

    Agent.get(agent, fn state ->
      assert [
               [[:test, :stop], _, _],
               [[:test, :start], _, _]
             ] = state

      state
    end)
  end

  def attach_metric(test_name, pid) do
    :telemetry.attach_many(
      test_name,
      [[:test, :start], [:test, :stop]],
      fn event, measurements, context, _config ->
        dbg()
        Agent.update(pid, fn state -> [[event, measurements, context] | state] end)
      end,
      nil
    )
  end
end
