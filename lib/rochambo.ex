defmodule Rochambo do
  @moduledoc """
    Provide methods for playing rock paper scissors
  """

  @doc """
    Takes two shapes and returns the winner

  ## Examples

    iex> Rochambo.play(%{"player1" => :rock, "player2" => :rock})
    :draw
    iex> Rochambo.play(%{"player1" => :rock, "player2" => :scissors})
    :player1
    iex> Rochambo.play(%{"player1" => :paper, "player2" => :scissors})
    :player2

  """
  def play(shapes) do
    [shape1, shape2] = Map.values(shapes)

    cond do
      shape1 == shape2 -> :draw
      shape1 == :rock && shape2 == :scissors -> :player1
      shape1 == :paper && shape2 == :rock -> :player1
      shape1 == :scissors && shape2 == :paper -> :player1
      true -> :player2
    end
  end
end
