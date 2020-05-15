OCAMLBUILD=ocamlbuild -classic-display \
		-tags annot,debug,thread \
		-use-ocamlfind -pkg graphics,unix \
		-ocamlc 'ocamlc str.cma' \
		-ocamlopt 'ocamlopt str.cmxa'

TARGET=native

all: 
	$(OCAMLBUILD) example.$(TARGET)

example:
	$(OCAMLBUILD) example.$(TARGET)

tictactoe: 
	$(OCAMLBUILD) tictactoe.$(TARGET)

tictactoe2:
	$(OCAMLBUILD) tictactoe2window.$(TARGET)

mandelbrot:
	$(OCAMLBUILD) mandelbrot.$(TARGET)

k_means:
	$(OCAMLBUILD) k_means.$(TARGET)

clean:
	$(OCAMLBUILD) -clean

realclean: clean
	rm -f *~

cleanall: realclean
