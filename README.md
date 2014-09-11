# ExSkel

`ExSkel` is a simple Elixir wrapper around the [Erlang `skel` framework](https://github.com/ParaPhrase/skel).

## Objectives

`ExSkel` has three objectives:

1. Make `skel` usable with Elixir's pipe (`|>`) operator.
2. Make `skel` more convenient, such as `ExSkel.yield/1`.
3. Provide some basic examples to help introduce `skel`.

## How to use ExSkel

Rather than write out the algorithms, `skel` is used to describe the desired algorithms. `ExSkel` uses the same format as `skel` for workflows. For reference, here is a basic grammar of the workflows:

    workflow ::= [workflow_item, ...]
    workflow_item ::=
      { :seq, worker } |
      { :pipe, workflow } |
      { :ord, workflow } |
      { :farm, workflow, worker_count } |
      { :reduce, reducer, decomposer } |
      { :map, workflow } |
      { :map, workflow, worker_count } |
      { :cluster, workflow, decomposer, recomposer } |
      { :feedback, workflow, condition }
    worker_count ::= Positive_integer
    decomposer ::= fn (Any) -> [Any, ...]
    condition ::= fn (Any) -> Boolean
    recomposer ::= fn ([Any, ...]) -> Any
    reducer ::= fn (Any, Any) -> Any
    worker ::= fn (Any) -> Any

These workflows are given to one of two functions: `ExSkel.async/2` or `ExSkel.sync/2`. `ExSkel.async/2` is asynchronous, and its results are received by subsequently calling `ExSkel.yield/0` or `ExSkel.yield/1` on the same process.

The `ExSkel` tests provide some (contrived) examples of how to use each of these workflows. They are compared against the `Enum` module. This comparison between sequential and parallel code makes it more clear what `skel` is doing under the covers. Note that several of the examples break the list of items into chunks. `skel` uses a list of lists to determine how work is spread across processes, usually one process per chunk.

## Operations

`skel` provides the eight following operations:

* `:seq`—Runs a sequential operation...not very interesting as-is. Almost always used as an inner workflow.
* `:pipe`—Acts like the Elixir pipe operator, but works between workflows. The pipe operation may be implied by simply supplying a list of workflows.
* `:farm`—Performs the given workflow using the specified number of processes.
* `:map`—Performs a standard map operation on all inputs. Automatically uses one process for each input, or the number of processes may be specified. Frequently used with `:reduce` to create a map reduce operation.
* `:reduce`—Performs a standard reduce operation on all inputs. Uses the first value of each input as the accumulator. Frequently used with `:map` to create a map reduce operation.
* `:ord`—Wrapper for other workflows. Instructs the inner workflow to return results in the same order as input.
* `:cluster`—A more generalized form of `:map`. Allows a decomposer and recomposer to be applied to the input before and after (respectively) the mapping workflow.
* `:feedback`—Repeatedly applies the given workflow to the inputs until the condition function returns a falsy value.

A more detailed tutorial of `skel` can be found [here](http://chrisb.host.cs.st-andrews.ac.uk/skel-test-master/tutorial/bin/tutorial.html). `skel` docs can be found [here](http://chrisb.host.cs.st-andrews.ac.uk/skel-test-master/doc/).

## License

> Copyright (c) 2014 Robert Brown
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.
