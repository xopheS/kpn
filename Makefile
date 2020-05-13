OCAMLBUILD=ocamlbuild -classic-display \
		-tags annot,debug,thread \
		-libs unix,graphics \
		-ocamlc 'ocamlc str.cma' \
		-ocamlopt 'ocamlopt str.cmxa'

TARGET=native

mandelbrot:
	$(OCAMLBUILD) mandelbrot.$(TARGET)

k_means:
	$(OCAMLBUILD) k_means.$(TARGET)


clean:
	$(OCAMLBUILD) -clean

realclean: clean
	rm -f *~

cleanall: realclean
