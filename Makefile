OCAMLBUILD=ocamlbuild -classic-display \
		-tags annot,debug,thread \
		-use-ocamlfind -pkg graphics,unix 

TARGET=native

tictactoe:
	$(OCAMLBUILD) tictactoe.$(TARGET)

mandelbrot:
	$(OCAMLBUILD) mandelbrot.$(TARGET)

example:
	$(OCAMLBUILD) example.$(TARGET)


clean:
	$(OCAMLBUILD) -clean

realclean: clean
	rm -f *~

cleanall: realclean
