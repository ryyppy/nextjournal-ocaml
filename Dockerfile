FROM ocaml/opam:alpine-3.6_ocaml-4.06.0

WORKDIR nextjournal-ocaml

# Remove the local repository and add the official mirror
RUN opam remote remove default && \
    opam remote add default https://opam.ocaml.org

# Install our dependencies
ADD nextjournal-ocaml.opam .

RUN opam pin add -yn nextjournal-ocaml . && \
    opam depext nextjournal-ocaml && \
    opam install --deps-only nextjournal-ocaml
