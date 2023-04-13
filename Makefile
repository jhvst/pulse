all: ocaml

.PHONY: extract-ocaml
extract-ocaml: extract-tactics extract-extraction

.PHONY: extract-tactics
extract-tactics:
	+$(MAKE) -C src/ocaml -f extract-tactics.Makefile

.PHONY: extract-extraction
extract-extraction:
	+$(MAKE) -C src/extraction

ifneq (,$(FSTAR_HOME))
  ifeq ($(OS),Windows_NT)
    OCAMLPATH := $(shell cygpath -m $(FSTAR_HOME)/lib);$(OCAMLPATH)
  else
    OCAMLPATH := $(FSTAR_HOME)/lib:$(OCAMLPATH)
  endif
  export OCAMLPATH
endif

ifeq ($(OS),Windows_NT)
  STEEL_HOME := $(shell cygpath -m $(CURDIR))
else
  STEEL_HOME := $(CURDIR)
endif

.PHONY: ocaml
ocaml:
	cd src/ocaml && dune build
	cd src/ocaml && dune install --prefix=$(STEEL_HOME)

clean:
	cd src/ocaml && { dune uninstall --prefix=$(STEEL_HOME) ; dune clean ; true ; }
