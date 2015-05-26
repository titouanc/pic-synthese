all: main.pdf

%.tex: %.md
	lunamark -t latex < $< > $@

main.pdf: main.tex elec.tex
	pdflatex $<
	pdflatex $<
