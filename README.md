# Rochambo

A GenServer that can play Rock, Paper, Scissors.

```elixir
alias Rochambo.Server

def go() do
  Server.status()
  # ... :need_players

  Server.join(name)
  # ... :joined

  Server.play(:rock)
  # ... "Player X played :scissors! You won!"

  Server.scores() 
  # ... %{"bob" => 1, "michael" => 0}

  Server.players()
  # ... ["bob", "michael"]
end
```
