defmodule VclockTest do
  use ExUnit.Case
  import Vclock

  test "sets internal state" do
    {:ok, c1} = start_link(1) 
    set(c1, 99)
    state = get(c1)
    assert state.data == 99
  end

  test "bumps on receive when empty" do
    {:ok, c1} = start_link(1)
    receive(c1, %{clock: %{2=>1}, data: 3, id: 2})
    state = get(c1)
    assert state.data == 3
    assert state.clock[1] == 1
  end

  test "replaces on receive newer" do
    {:ok, c1} = start_link(1)
    receive(c1, %{clock: %{2=>1}, data: 3, id: 2})
    receive(c1, %{clock: %{2=>2,1=>1}, data: 5, id: 2})
    state = get(c1)
    assert state.data == 5
    assert state.clock == %{2=>2,1=>2}
  end

  test "ignores on receive older" do
    {:ok, c1} = start_link(1)
    receive(c1, %{clock: %{2=>2}, data: 3, id: 2})
    receive(c1, %{clock: %{2=>1}, data: 5, id: 2})
    state = get(c1)
    assert state.data == 3
    assert state.clock == %{1=>1, 2=>2}

    receive(c1, %{clock: %{2=>2}, data: 5, id: 2})
    state = get(c1)
    assert state.data == 3
  end

  test "resolves conflict concurrent" do
    {:ok, c1} = start_link(1)
    set(c1, 99)
    set(c1, 88)
    receive(c1, %{clock: %{1=>1,2=>1}, data: 3, id: 2})
    state = get(c1)
    assert state.data == 3
    assert state.clock == %{1=>3,2=>1}
  end
end
