OCAMLBUILD=ocamlbuild -classic-display \
		-tags annot,debug,thread \
		-libs unix
		#-use-ocamlfind -pkg graphics\
		#-libs unix

TARGET=native

tictactoe:
	$(OCAMLBUILD) tictactoe.$(TARGET)

#mandelbrot:
#	$(OCAMLBUILD) mandelbrot.$(TARGET)

example:
	$(OCAMLBUILD) example.$(TARGET)


clean:
	$(OCAMLBUILD) -clean

realclean: clean
	rm -f *~

cleanall: realclean
