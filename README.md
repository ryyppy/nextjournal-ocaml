# nextjournal-ocaml

## Setup for local development

Install opam and use it to install the right OCaml version: `opam
switch 4.06.0` (don't forget to source your new opam environment via
`$(opam config env)`).

Now install the project dependencies:

```bash
opam pin add nextjournal-ocaml -y .
```

If you want to build the ocaml socket-server for a Linux environment on a Mac,
build the Docker image for this project:

```bash
docker build -t nj-ocaml .
```

If you want to use the watch-mode, you need to install `watchman`:
https://facebook.github.io/watchman/docs/install.html#installing-on-os-x-via-homebrew


## Building / Running

The building instructions are useful to build a bytecode binary.  This is
mostly useful for developing the code... follow the `dist` instructions to
create a dist file.

```
# Builds all build artifacts
make build

# Starts the socket-server (make sure to build first)
make start

# Cleans all build artifacts
make clean

# Uses watchman-make to watch all source files and rebuilds on change
make watch

# Runs the docker container for manual building (mounts project as a volume)
make docker-run
```
## Build dist

```
# This creates a toplevel `dist/socket_server.ml` ready for nextjournal
make dist

# Test generated file
ocaml dist/socket_server.ml
```
