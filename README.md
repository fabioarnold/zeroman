# Zero Man

A basic Mega Man clone with Zero as the main character.

Try it: https://fabioarnold.de/games/zeroman/

## Building and running

```bash
# Get the source
$ git clone https://github.com/fabioarnold/zeroman

# Build `zig-out/lib/main.wasm`
$ cd zeroman
$ zig build

# Run an HTTP server
$ zig build serve

# NOTE that the HTTP server will automatically rebuild the game whenever it is fetched
```
