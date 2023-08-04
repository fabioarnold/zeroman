# Zero Man

A basic Mega Man clone with Zero as the main character.

Try it: https://zeroman.space

## Building and running

Needs [Zig](https://ziglang.org/download/) version 0.11.0.

```bash
# Get the source
$ git clone https://github.com/fabioarnold/zeroman

# Build `zig-out/lib/main.wasm`
$ cd zeroman
$ zig build

# Run an HTTP server
$ python3 -m http.server
```
