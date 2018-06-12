SHELL = /bin/sh

mytop = mytop
context = 4.06.0
working_dir = $(realpath .)

build:
	jbuilder build --dev @install

clean:
	jbuilder clean
	rm ${mytop} || true

dist:
	mkdir -p dist
	# Adds the commit hash in the header
	(git log -1 --format="(* Revision: nextjournal-ocaml: %h *)%n" ; cat prelude.ml bin/server.ml ) > dist/socket_repl.ml

run-dist: dist
	ocaml dist/socket_server.ml

start:
	jbuilder exec --context=${context} bin/server.bc

run-example:
	jbuilder exec --context=${context} examples/ex2.bc

install: build

watch:
	watchman-make -p '**/*.ml' '**/*.mli' 'Makefile' -t build

docker-run:
	docker run -v ${working_dir}:/home/opam/nextjournal-ocaml -it nj-ocaml bash

.PHONY: dist build clean build run-example install watch docker-run
