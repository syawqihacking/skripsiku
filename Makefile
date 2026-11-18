# ==============================================================================
# MAKEFILE UNTUK PROYEK SKRIPSI LATEX
# ==============================================================================

.PHONY: all pdf quick clean

all: pdf

pdf:
	./compile.sh

quick:
	./compile.sh quick

clean:
	./compile.sh clean
