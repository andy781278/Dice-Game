# Dice Game

Online multiplayer dice game for up to 6 players, built in Godot 4.

## How it plays

Players take turns in a random order and face each other in 1v1 dice battles. The physics dice decide each roll, and the score is read after the dice stop moving. Losing players are eliminated. Between rounds, there is a timed shop phase.

## Networking

- Uses Godot's ENet multiplayer API. One player hosts, and others join by entering the host's IP address and port.
- The host spawns a player node for each connected peer.
- All game logic runs on the host. The host sends turn order, dice results, eliminations, and shop timing to clients through RPCs, so every client sees the same game state.

## Running it

1. Open the project in Godot 4.
2. Run the game, choose Host on one machine, and choose Join on the others with the host's IP address and port.

## Built with

Godot 4, GDScript
