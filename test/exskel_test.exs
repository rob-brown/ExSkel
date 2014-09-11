defmodule ExSkelTest do
  use ExUnit.Case, async: true

  doctest ExSkel

  def default_list, do: Enum.to_list 1..10_000

  test "async" do
    1..5
			|> Enum.to_list
			|> ExSkel.async [{ :seq, &(&1 * &1) }]
    assert [ 1, 4, 9, 16, 25 ] == ExSkel.yield
  end

  test "yield before timeout" do
    1..5
      |> Enum.to_list
      |> ExSkel.async [{ :seq, &(&1 * &1) }]
    assert { :ok, [ 1, 4, 9, 16, 25 ] } == ExSkel.yield(100)
  end

  test "yield after timeout" do
    1..5
      |> Enum.to_list
      |> ExSkel.async [{ :seq, fn x -> :timer.sleep(10); x * x end }]
    assert { :timeout, nil } == ExSkel.yield(1)
  end

  test "seq" do
    mapper = &(&1 * 2)
    assert ExSkel.sync(default_list, [{ :seq, mapper }]) == Enum.map(default_list, mapper)
  end

  test "pipe" do
    mapper1 = &(&1 * 2)
    mapper2 = &(&1 + 1)
    result = default_list |> ExSkel.sync([{ :pipe, [{ :seq, mapper1 }, { :seq, mapper2 }] }])
    assert result == (default_list |> Enum.map(mapper1) |> Enum.map(mapper2))
  end

  test "implicit pipe" do
    mapper1 = &(&1 * 2)
    mapper2 = &(&1 + 1)
    result = default_list |> ExSkel.sync([{ :seq, mapper1 }, { :seq, mapper2 }])
    assert result == (default_list |> Enum.map(mapper1) |> Enum.map(mapper2))
  end

  test "map" do
    mapper = &(&1 * 2)
    result = default_list
               |> Enum.chunk(1000)
               |> ExSkel.sync([{ :map, [{ :seq, mapper }] }])
               |> List.flatten
               |> Enum.sort
    assert result == default_list |> Enum.map(mapper)
  end

  test "ordered map" do
    mapper = &(&1 * 2)
    result = default_list
			         |> Enum.chunk(1000)
			         |> ExSkel.sync([{ :ord, [{ :map, [{ :seq, mapper }] }] }])
			         |> List.flatten
    assert result == default_list |> Enum.map(mapper)
  end

  test "farm" do
    mapper = &(&1 * 2)
    result = default_list
			         |> ExSkel.sync([{ :farm, [{ :seq, mapper }], 1000 }])
               |> Enum.sort
    assert result == default_list |> Enum.map(mapper)
  end

  test "ordered farm" do
    mapper = &(&1 * 2)
    result = default_list
               |> ExSkel.sync([{ :ord, [{ :farm, [{ :seq, mapper }], 1000 }] }])
    assert result == default_list |> Enum.map(mapper)
  end

  test "reduce" do
    reducer = &(&1 + &2)
    result = default_list
               |> Enum.chunk(1000)
               |> ExSkel.sync([{ :reduce, reducer, &(&1) }])
        			 |> wrap_list
               |> ExSkel.sync([{ :reduce, reducer, &(&1) }])
               |> unwrap_list
    assert result == default_list |> Enum.reduce(reducer)
  end

  test "reduce with decomposer" do
    reducer = fn {x, y}, {acc_x, acc_y} -> {x + acc_x, y * acc_y} end
    decomposer = fn x -> Enum.map(x, &({&1, &1})) end
    result = default_list
               |> wrap_list
               |> ExSkel.sync([{ :reduce, reducer, decomposer }])
               |> unwrap_list
    assert result == default_list |> decomposer.() |> Enum.reduce(reducer)
  end

  test "map reduce" do
    mapper = &(&1 * 2)
    reducer = &(&1 + &2)
		result = default_list
               |> Enum.chunk(1000)
		           |> ExSkel.sync([{ :map, [{ :seq, mapper }] },
											         { :reduce, reducer, &(&1) }])
               |> wrap_list
               |> ExSkel.sync([{ :reduce, reducer, &(&1) }])
               |> List.first
    assert result == (default_list |> Enum.map(mapper) |> Enum.reduce(reducer))
  end

  test "cluster" do
    mapper = &(&1 * 2)
    result = default_list
               |> Enum.chunk(1000)
               |> ExSkel.sync([{ :cluster, [{ :seq, mapper }], &(&1), &(&1) }])
               |> List.flatten
               |> Enum.sort
    assert result == default_list |> Enum.map(mapper)
  end

  test "cluster with decomposer" do
    decomposer = &(&1 ++ &1)
    mapper = &(&1 * 2)
    result = default_list
               |> Enum.chunk(1000)
               |> ExSkel.sync([{ :cluster, [{ :seq, mapper }], decomposer, &(&1) }])
               |> List.flatten
               |> Enum.sort
    assert result == default_list |> decomposer.() |> Enum.map(mapper) |> Enum.sort
  end

  test "ordered cluster with decomposer and recomposer" do
    decomposer = &([{&1, &1}])
    mapper = fn {x, y} -> {x * 2, y + 3} end
    recomposer = fn [{x, y}] -> x + y end
    result = default_list
               |> ExSkel.sync([{ :ord, [{ :cluster, [{ :seq, mapper }], decomposer, recomposer }] }])
    expected = default_list
                 |> Enum.map(decomposer)
                 |> Enum.map(&unwrap_list/1)
                 |> Enum.map(mapper)
                 |> Enum.map(&wrap_list/1)
                 |> Enum.map(recomposer)
    assert result == expected
  end

  test "feedback" do
    mapper = &(&1 * 2)
    condition = &(&1 < 1000)
    feedback = &(feedback_simulator(&1, mapper, condition))
    result = default_list
               |> ExSkel.sync([{ :feedback, [{ :seq, mapper }], condition }])
               |> Enum.sort
    assert result == (default_list |> Enum.map(feedback) |> Enum.sort)
  end

  defp wrap_list(x), do: [x]
  defp unwrap_list([x]), do: x

  defp feedback_simulator(x, mapper, condition), do: _feedback_simulator(mapper.(x), mapper, condition)
  defp _feedback_simulator(x, mapper, condition) do
    if condition.(x) do
      feedback_simulator(x, mapper, condition)
    else
      x
    end
  end
end
