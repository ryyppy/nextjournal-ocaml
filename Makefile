SHELL = /bin/sh

context = 4.06.0
working_dir = $(realpath .)

build:
	jbuilder build --dev @install

clean:
	jbuilder clean

start:
	jbuilder exec --context=${context} bin/server.bc

run-example:
	jbuilder exec --context=${context} examples/ex2.bc

install: build

watch:
	watchman-make -p '**/*.ml' '**/*.mli' 'Makefile' -t build

docker-run:
	docker run -v ${working_dir}:/home/opam/nextjournal-ocaml -it nj-ocaml bash

.PHONY: build clean build run-example install watch atd docker-run
