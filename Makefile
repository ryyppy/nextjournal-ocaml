SHELL = /bin/sh
executable = ./_build/4.06.1/examples/ex2.bc

socket_server = ./_build/4.06.1/bin/server.bc

build:
	jbuilder build --dev @install

clean:
	jbuilder clean

start: build
	$(socket_server)

run: build
	$(executable)

install: build

atd:
	atdgen -t src/unrepl.atd
	atdgen -j src/unrepl.atd

watch:
	watchman-make -p '**/*.ml' '**/*.mli' 'Makefile' -t build

.PHONY: build clean build run install watch atd
