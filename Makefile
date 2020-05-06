OCAMLBUILD=ocamlbuild -classic-display \
		-tags annot,debug,thread \
		-libs unix \
		-ocamlc 'ocamlc str.cma' \
		-ocamlopt 'ocamlopt str.cmxa'
TARGET=native

example:
	$(OCAMLBUILD) k_means.$(TARGET)


clean:
	$(OCAMLBUILD) -clean

realclean: clean
	rm -f *~

cleanall: realclean
