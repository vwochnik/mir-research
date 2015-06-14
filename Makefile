PDFLATEX	     ?= pdflatex
BIBTEX		     ?= bibtex8 --wolfgang
MAKEGLOSSARIES ?= makeglossaries

## Name of the target file, minus .pdf: e.g., TARGET=mypaper causes this
## Makefile to turn mypaper.tex into mypaper.pdf.
TARGET ?= index
PDFTARGETS += $(TARGET).pdf

## If $(TARGET).tex refers to .bib files like \bibliography{foo,bar}, then
## $(BIBFILES) will contain foo.bib and bar.bib, and both files will be added as
## dependencies to $(PDFTARGETS).
## Effect: updating a .bib file will trigger re-typesetting.
BIBFILES = $(patsubst %,%.bib,\
		$(shell grep '^[^%]*\\bibliography{' $(TARGET).tex | \
			sed -e 's/^[^%]*\\bibliography{\([^}]*\)}.*/\1/' \
			    -e 's/, */ /g'))

## Add \input'ed or \include'd files to $(PDFTARGETS) dependencies.
INCLUDEDTEX = $(patsubst %,%.tex,\
		$(shell grep '^[^%]*\\\(input\|include\){' $(TARGET).tex | \
			sed 's/[^{]*{\([^}]*\)}.*/\1/'))

AUXFILES = $(foreach T,$(PDFTARGETS:.pdf=), $(T).aux)
AUXFILES += $(patsubst %.tex,%.aux, $(INCLUDEDTEX))
LOGFILES = $(patsubst %.aux,%.log, $(AUXFILES))

# .PHONY names all targets that aren't filenames
.PHONY: all clean pdf

all: pdf $(AFTERALL)

pdf: $(PDFTARGETS)

# to generate aux but not pdf from pdflatex, use -draftmode
.INTERMEDIATE: $(AUXFILES)
%.aux: %.tex
	$(PDFLATEX) -draftmode $*
	$(PDFLATEX) -draftmode $(TARGET).tex

# introduce BibTeX dependency if we found a \bibliography
ifneq ($(strip $(BIBFILES)),)
BIBDEPS = %.bbl
%.bbl: %.aux $(BIBFILES)
	$(BIBTEX) $*
endif

$(PDFTARGETS): %.pdf: %.tex %.aux $(BIBDEPS) $(INCLUDEDTEX)
	@if [ -a $(TARGET).glo ]; then \
	  $(MAKEGLOSSARIES) $(TARGET).glo; fi
	$(PDFLATEX) $*
ifneq ($(strip $(BIBFILES)),)
	@if grep -q "undefined references" $*.log; then \
		$(BIBTEX) $* && $(PDFLATEX) $*; fi
endif
	@while grep -q "Rerun to" $*.log; do \
		$(PDFLATEX) $*; done

clean:
	$(RM) $(foreach T,$(PDFTARGETS:.pdf=), \
		$(T).out $(T).pdf $(T).blg $(T).bbl \
		$(T).lof $(T).lot $(T).toc $(T).idx \
		$(T).nav $(T).snm) \
		$(T).glg $(T).glo $(T).gls \ $(T).glsdefs $(T).ist \
		$(AUXFILES) $(LOGFILES)
