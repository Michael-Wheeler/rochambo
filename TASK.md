# Task

Implement a GenServer in Elixir to play a game of rock, paper, scissors.

- It should let two different processes join and register a player name
- It should be possible to get a list of all connected player names
- A process cannot join more than once
- There should be two game states - `:need_players` and `:waiting_for_gambits`, which can be queried.
- No more than two processes can join
- No hands may be played until both players have joined
- It should be possible to connect to the GenServer remotely, i.e. from a different process (in the Operating System sense) or a completely different machine. 
- When there are two players, each player can independently play their hand. The function to do this (`&Rochambo.Server.play/1`) should not return until the result of the match can be determined. In other words, the first player must wait to get the result of the match until the second has played their hand.
- It should keep score and be able to return the score when queried. 

## Project structure

Provided is a mix library with unit tests and an empty GenServer, `Rochambo.Server`. An external API (as used by the tests) should be implemented in order to abstract away from calling GenServer functions directly. You need only implement code in `Rochambo.Server` but you may add any additional tests or modules you wish, as long as you leave the original test intact.

## Hints

- Consider working against the tests (run `mix test`)
- Work separately on a function to determine the outcome of a game between two players and consider adding a test for it
- As the tests demonstrate, apart from providing a name initially, the external interface does not provide for passing in an explicit player ID, so you will have to find another way of matching up messages to the GenServer to the sender.
- There are several ways to broadcast the location of and find a process across the network. Make sure that the GenServer can be found using one of these mechanisms.

Good luck!