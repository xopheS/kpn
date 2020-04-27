OCAMLBUILD=ocamlbuild -use-ocamlfind -pkg graphics \
		-classic-display \
		-tags annot,debug,thread
TARGET=native

mandelbrot:
	$(OCAMLBUILD) mandelbrot.$(TARGET)

example:
	$(OCAMLBUILD) example.$(TARGET)


clean:
	$(OCAMLBUILD) -clean

realclean: clean
	rm -f *~

cleanall: realclean
