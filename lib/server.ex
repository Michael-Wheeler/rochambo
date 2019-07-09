defmodule Rochambo.Server do
  @moduledoc """
  A Genserver which allows two players to play rock paper scissors
  """
  use GenServer

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: :rps_server)
  end

  def join(name) do
    GenServer.call(:rps_server, {:join, name})
  end

  def play(shape) do
    GenServer.cast(:rps_server, {:play, shape, self()})
    Rochambo.Server.poll_results()
  end

  def poll_results() do
    # Wait outside case statement to allow both players a chance to recieve the scores
    Process.sleep(100)
    result = GenServer.call(:rps_server, :get_game_result)

    case result == :waiting do
      true ->
        IO.puts("Waiting for game to be played")
        Rochambo.Server.poll_results()

      false ->
        result
    end
  end

  def status() do
    GenServer.call(:rps_server, :status)
  end

  def get_players() do
    GenServer.call(:rps_server, :get_players)
  end

  def scores() do
    GenServer.call(:rps_server, :state)
  end

  def shapes() do
    GenServer.call(:rps_server, :shapes)
  end

  def stop() do
    GenServer.stop(:rps_server, :normal, :infinity)
  end

  # GenServer
  @doc false
  def init(:ok) do
    IO.puts("Game started, please join with your player name")
    names = %{}
    scores = %{}
    shapes = %{}
    result = %{}
    {:ok, {names, scores, shapes, result}}
  end

  @doc false
  def handle_call({:join, name}, from, state) do
    {names, scores, shapes, result} = state
    {client_pid, _} = from

    cond do
      Map.has_key?(names, client_pid) ->
        IO.puts("You have already joined as #{name}!")
        {:reply, {:error, "Already joined!"}, state}

      length(Map.keys(names)) == 2 ->
        IO.puts("#{name} cannot join as the game is full")
        {:reply, {:error, "Already full!"}, state}

      true ->
        IO.puts("#{name} is joining")
        updated_names = Map.put(names, client_pid, name)
        updated_scores = Map.put(scores, name, 0)
        updated_shapes = Map.put(shapes, client_pid, :empty)
        {:reply, :joined, {updated_names, updated_scores, updated_shapes, result}}
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
  def handle_call(:get_game_result, from, state) do
    {_, _, _, result} = state
    {client_pid, _} = from

    case result != %{} do
      true ->
        {:reply, Map.fetch!(result, client_pid), state}

      false ->
        IO.puts("Game is yet to be played")
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
  def handle_cast({:play, shape, client_pid}, state) do
    {names, scores, shapes, result} = state

    # Can't play until both players have joined
    case length(Map.keys(names)) != 2 do
      true ->
        {:noreply, state}

      false ->
        nil
    end

    # Start new round if existing shapes found
    updated_shapes =
      case Map.get(shapes, client_pid) != :empty do
        true ->
          [player1, player2] = Map.keys(shapes)
          updated_shapes = Map.replace!(shapes, player1, :empty)
          Map.replace!(updated_shapes, player2, :empty)

        false ->
          shapes
      end

    updated_shapes = Map.replace!(updated_shapes, client_pid, shape)

    # Continue to play game if both players have played
    case length(Map.keys(updated_shapes)) == 2 &&
           !Enum.member?(Map.values(updated_shapes), :empty) do
      true ->
        {_, updated_scores, _, updated_result} =
          Rochambo.Server.play_game({names, scores, updated_shapes, result})

        {:noreply, {names, updated_scores, updated_shapes, updated_result}}

      false ->
        {:noreply, {names, scores, updated_shapes, result}}
    end
  end

  @doc false
  def terminate(_reason, state) do
    IO.puts("Ending Game.")
    IO.inspect(state)
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
      case Rochambo.play(shapes) do
        :draw ->
          {%{player1 => "draw", player2 => "draw"}, scores}

        :player1 ->
          {%{player1 => "you won!", player2 => "you lost!"},
           Map.update!(scores, player1_name, fn x -> x + 1 end)}

        :player2 ->
          {%{player1 => "you lost!", player2 => "you won!"},
           Map.update!(scores, player2_name, fn x -> x + 1 end)}
      end

    IO.puts("Game played, results are: #{inspect(result)}")
    {names, updated_scores, shapes, result}
  end
end
