#!/bin/bash
set -e

# ==============================================================================
# SKRIP KOMPILASI SKRIPSI LATEX (TEX LIVE)
# Penggunaan:
#   ./compile.sh        -> Kompilasi penuh multi-pass (pdflatex + bibtex)
#   ./compile.sh quick  -> Kompilasi cepat satu pass
#   ./compile.sh clean  -> Membersihkan berkas sementara LaTeX
# ==============================================================================

if [ "$1" == "clean" ]; then
    echo "Membersihkan berkas sementara build LaTeX..."
    rm -f *.aux *.bbl *.bcf *.blg *.dvi *.fdb_latexmk *.fls *.lof *.log *.lot *.out *.run.xml *.synctex.gz *.toc
    echo "Pembersihan selesai."
    exit 0
fi

if [ "$1" == "quick" ]; then
    echo "Menjalankan kompilasi cepat (1 pass)..."
    pdflatex -interaction=nonstopmode -halt-on-error main.tex
    echo "Selesai. main.pdf telah diperbarui."
    exit 0
fi

echo "=========================================================="
echo "Memulai Kompilasi Skripsi LaTeX (Multi-Pass)"
echo "=========================================================="

echo "[1/4] Pass 1: Membangun indeks awal struktur dokumen..."
pdflatex -interaction=nonstopmode -halt-on-error main.tex > /dev/null

echo "[2/4] Pass 2: Memproses sitasi daftar pustaka (BibTeX APA)..."
bibtex main > /dev/null

echo "[3/4] Pass 3: Menghubungkan sitasi dengan teks skripsi..."
pdflatex -interaction=nonstopmode -halt-on-error main.tex > /dev/null

echo "[4/4] Pass 4: Finalisasi cross-reference (TOC, LOT, LOF)..."
pdflatex -interaction=nonstopmode -halt-on-error main.tex

echo "=========================================================="
echo "BERHASIL! main.pdf telah dibuat dengan sempurna."
echo "=========================================================="
