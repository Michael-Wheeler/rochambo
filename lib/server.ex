defmodule Rochambo.Server do
  @moduledoc """
  A Genserver which allows two players to play rock paper scissors
  """
  use GenServer

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: {:global, :rps_server})
  end

  def join(name) do
    GenServer.call({:global, :rps_server}, {:join, name})
  end

  def play(shape) do
    GenServer.call({:global, :rps_server}, {:play, shape}, :infinity)
  end

  def status() do
    GenServer.call({:global, :rps_server}, :status)
  end

  def get_players() do
    GenServer.call({:global, :rps_server}, :get_players)
  end

  def scores() do
    GenServer.call({:global, :rps_server}, :state)
  end

  def shapes() do
    GenServer.call({:global, :rps_server}, :shapes)
  end

  def stop() do
    GenServer.stop({:global, :rps_server}, :normal, :infinity)
  end

  # GenServer
  @doc false
  def init(:ok) do
    names = %{}
    scores = %{}
    shapes = %{}
    result = %{}
    {:ok, {names, scores, shapes, result}}
  end

  @doc false
  def handle_call({:join, name}, from, state) do
    {names, scores, shapes, _} = state
    {client_pid, _} = from

    cond do
      Map.has_key?(names, client_pid) ->
        {:reply, {:error, "Already joined!"}, state}

      length(Map.keys(names)) == 2 ->
        {:reply, {:error, "Already full!"}, state}

      true ->
        updated_names = Map.put(names, client_pid, name)
        updated_scores = Map.put(scores, name, 0)
        updated_shapes = Map.put(shapes, client_pid, :empty)
        updated_result = Map.put(shapes, client_pid, :empty)
        {:reply, :joined, {updated_names, updated_scores, updated_shapes, updated_result}}
    end
  end

  @doc false
  def handle_call(:status, _from, state) do
    {names, _, _, _} = state

    case length(Map.keys(names)) == 2 do
      true -> {:reply, :waiting_for_gambits, state}
      false -> {:reply, :need_players, state}
    end
  end

  @doc false
  def handle_call({:get_game_result, client_pid}, _from, state) do
    {names, scores, shapes, result} = state

    case Map.fetch!(result, client_pid) != :empty do
      true ->
        updated_result = Map.replace!(result, client_pid, :empty)
        {:reply, Map.fetch!(result, client_pid), {names, scores, shapes, updated_result}}

      false ->
        {:reply, :waiting, state}
    end
  end

  @doc false
  def handle_call(:get_players, _from, state) do
    {names, _, _, _} = state
    {:reply, Map.values(names), state}
  end

  @doc false
  def handle_call(:state, _from, state) do
    {_, scores, _, _} = state
    {:reply, scores, state}
  end

  def handle_call(:shapes, _from, state) do
    {_, _, shapes, _} = state
    {:reply, shapes, state}
  end

  @doc false
  def handle_call({:play, shape}, from, state) do
    {names, scores, shapes, result} = state
    {client_pid, _} = from

    updated_shapes = Map.replace!(shapes, client_pid, shape)

    # Continue to play game if both players have played
    updated_state =
      case length(Map.keys(updated_shapes)) == 2 &&
             !Enum.member?(Map.values(updated_shapes), :empty) do
        true ->
          {_, updated_scores, _, updated_result} =
            Rochambo.Server.play_game({names, scores, updated_shapes, result})

          # Clear shapes for next round
          [player1, player2] = Map.keys(shapes)

          cleared_shapes =
            Map.replace!(updated_shapes, player1, :empty)
            |> Map.replace!(player2, :empty)

          {names, updated_scores, cleared_shapes, updated_result}

        false ->
          {names, scores, updated_shapes, result}
      end

    spawn_link(fn ->
      poll_server_results(from)
    end)

    {:noreply, updated_state}
  end

  @doc false
  def terminate(_reason, _state) do
    :ok
  end

  @doc false
  def play_game(state) do
    {names, scores, shapes, _result} = state
    [player1, player2] = Map.keys(names)

    # Get player names to update scoresheet
    player1_name = Map.get(names, player1)
    player2_name = Map.get(names, player2)

    {result, updated_scores} =
      case Rochambo.Server.handle_play(shapes) do
        :draw ->
          {%{player1 => "draw", player2 => "draw"}, scores}

        :player1 ->
          {%{player1 => "you won!", player2 => "you lost!"},
           Map.update!(scores, player1_name, fn x -> x + 1 end)}

        :player2 ->
          {%{player1 => "you lost!", player2 => "you won!"},
           Map.update!(scores, player2_name, fn x -> x + 1 end)}
      end

    {names, updated_scores, shapes, result}
  end

  @doc """
    Takes two shapes and returns the winner

  ## Examples

    iex> Rochambo.Server.handle_play(%{"player1" => :rock, "player2" => :rock})
    :draw

    iex> Rochambo.Server.handle_play(%{"player1" => :rock, "player2" => :scissors})
    :player1

    iex> Rochambo.Server.handle_play(%{"player1" => :paper, "player2" => :scissors})
    :player2

  """
  def handle_play(shapes) do
    [shape1, shape2] = Map.values(shapes)

    cond do
      shape1 == shape2 -> :draw
      shape1 == :rock && shape2 == :scissors -> :player1
      shape1 == :paper && shape2 == :rock -> :player1
      shape1 == :scissors && shape2 == :paper -> :player1
      true -> :player2
    end
  end

  def poll_server_results(from) do
    {client_pid, _} = from
    result = GenServer.call({:global, :rps_server}, {:get_game_result, client_pid})

    case result == :waiting do
      true ->
        Process.sleep(100)
        Rochambo.Server.poll_server_results(from)

      false ->
        GenServer.reply(from, result)
    end
  end
end
