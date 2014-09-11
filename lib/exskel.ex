defmodule ExSkel do
	@moduledoc """
	A simple Elixir wrapper around the `skel` Erlang library. See
	`exskel_test.exs` for more detailed examples.
	"""

	@doc """
	Asynchronously runs the workflow against the given input. Receive results by
	calling `yield/0` or `yield/1`.

			iex> ExSkel.async([1, 2, 3], [{ :seq, &(&1 * &1) }])
			iex> ExSkel.yield()
			[1, 4, 9]
	"""
	def async(input, workflow) do
	  :skel.run(workflow, input)
	end

	@doc """
	Call after calling `async/2`. Waits for the results or the timeout,
	whichever comes first.

		iex> ExSkel.async([1, 2, 3], [{ :seq, &(&1 * &1) }])
		iex> ExSkel.yield(100)
		{:ok, [1, 4, 9]}

		iex> ExSkel.async([1, 2, 3], [{ :seq, fn x -> :timer.sleep(10); x * x end }])
		iex> ExSkel.yield(1)
		{:timeout, nil}
	"""
	def yield(milliseconds) when is_number(milliseconds) do
	  receive do
      { :sink_results, results} ->
        { :ok, results }
      after milliseconds ->
        { :timeout, nil }
    end
	end

	@doc """
	Call after calling `async/2`. Blocks until the results are received.

		iex> ExSkel.async([[1, 2, 3]], [{ :map, [{ :seq, &(&1 * &1) }]}])
		iex> ExSkel.yield()
		[[1, 4, 9]]
	"""
	def yield() do
	  receive do
      { :sink_results, results} -> results
    end
	end

	@doc """
	Synchronously runs the workflow against the given input.

		iex> ExSkel.sync([[1, 2, 3]], [{ :map, [{ :seq, &(&1 * &1) }]}])
		[[1, 4, 9]]
	"""
	def sync(input, workflow) do
	  :skel.do(workflow, input)
	end
end
