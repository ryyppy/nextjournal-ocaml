SHELL = /bin/sh
executable = ./_build/4.06.1/examples/ex1.bc

build:
	jbuilder build --dev @install

clean:
	jbuilder clean

run: build
	$(executable)

install: build

watch:
	watchman-make -p '**/*.ml' '**/*.mli' 'Makefile' -t build

.PHONY: build clean build run install watch
