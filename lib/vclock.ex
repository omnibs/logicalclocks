defmodule Vclock do
  use GenServer
  @moduledoc """
  Vector clock GenServer
  """

  def start_link(id) do
    GenServer.start_link(__MODULE__, %{clock: %{}, data: nil, id: id})
  end

  def receive(s, incoming), do: GenServer.cast(s, {:receive, incoming})
  def set(s, data), do: GenServer.cast(s, {:set, data})
  def get(s), do: GenServer.call(s, :get)

  def handle_cast({:receive, incoming}, state) do
    state = case compare(incoming.clock, state.clock) do
      :gt -> bump(incoming, state.id)
      :lt -> state
      :concurrent -> bump(incoming, state.id, state.clock[state.id])
    end
    {:noreply, state}
  end

  def handle_cast({:set, data}, state) do
    state = bump(state, state.id)
    state = %{state | data: data}
    {:noreply, state}
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  defp bump(state, id, initial \\ nil) do
    clock = Map.put(state.clock, id, (initial || state.clock[id]))
    clock = Map.put(clock, id, (clock[id] || 0)+1)
    %{state | clock: clock, id: id}
  end
  defp compare(c1, c2) do
    all_keys = Map.merge(c1,c2) |> Enum.map(fn {k,_v} -> k end)
    comparison = Enum.reduce(all_keys, {true,true}, fn (k,{a1,a2}) ->
      {a1 && gt(c1[k], c2[k]), a2 && gt(c2[k], c1[k])}
    end)

    case comparison do
      {true, false} -> :gt
      {false, true} -> :lt
      _ -> :concurrent
    end
  end
  defp gt(nil,_), do: false
  defp gt(_,nil), do: true
  defp gt(i,j), do: i >= j
end
