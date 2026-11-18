#!/bin/bash
set -e

# ==============================================================================
# SKRIP KOMPILASI PROPOSAL SKRIPSI LATEX (TEX LIVE)
# Penggunaan:
#   ./compile.sh        -> Kompilasi penuh multi-pass (pdflatex + bibtex)
#   ./compile.sh quick  -> Kompilasi cepat satu pass
#   ./compile.sh docx   -> Mengonversi hasil PDF menjadi Word (proposal_sentimen_madura.docx)
#   ./compile.sh clean  -> Membersihkan berkas sementara LaTeX
# ==============================================================================

if [ "$1" == "clean" ]; then
    echo "Membersihkan berkas sementara build LaTeX..."
    rm -f *.aux *.bbl *.bcf *.blg *.dvi *.fdb_latexmk *.fls *.lof *.log *.lot *.out *.run.xml *.synctex.gz *.toc
    echo "Pembersihan selesai."
    exit 0
fi

if [ "$1" == "docx" ]; then
    if [ ! -f "main.pdf" ]; then
        echo "main.pdf belum ditemukan. Menjalankan kompilasi cepat terlebih dahulu..."
        pdflatex -interaction=nonstopmode -halt-on-error main.tex
    fi
    echo "Mengonversi main.pdf ke format Microsoft Word (proposal_sentimen_madura.docx)..."
    python3 -c "from pdf2docx import Converter; cv = Converter('main.pdf'); cv.convert('proposal_sentimen_madura.docx'); cv.close()"
    python3 -c "
import docx
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
doc = docx.Document('proposal_sentimen_madura.docx')
for p in doc.paragraphs:
    for run in p.runs:
        run.font.name = 'Times New Roman'
        rPr = run._element.get_or_add_rPr()
        rFonts = rPr.find(qn('w:rFonts'))
        if rFonts is None:
            rFonts = OxmlElement('w:rFonts')
            rPr.append(rFonts)
        rFonts.set(qn('w:ascii'), 'Times New Roman')
        rFonts.set(qn('w:hAnsi'), 'Times New Roman')
        rFonts.set(qn('w:cs'), 'Times New Roman')
for t in doc.tables:
    for row in t.rows:
        for cell in row.cells:
            for p in cell.paragraphs:
                for run in p.runs:
                    run.font.name = 'Times New Roman'
                    rPr = run._element.get_or_add_rPr()
                    rFonts = rPr.find(qn('w:rFonts'))
                    if rFonts is None:
                        rFonts = OxmlElement('w:rFonts')
                        rPr.append(rFonts)
                    rFonts.set(qn('w:ascii'), 'Times New Roman')
                    rFonts.set(qn('w:hAnsi'), 'Times New Roman')
                    rFonts.set(qn('w:cs'), 'Times New Roman')
doc.save('proposal_sentimen_madura.docx')
"
    echo "Selesai. proposal_sentimen_madura.docx berhasil diperbarui dengan font Times New Roman."
    exit 0
fi

if [ "$1" == "quick" ]; then
    echo "Menjalankan kompilasi cepat (1 pass)..."
    pdflatex -interaction=nonstopmode -halt-on-error main.tex
    echo "Selesai. main.pdf telah diperbarui."
    exit 0
fi

echo "=========================================================="
echo "Memulai Kompilasi Proposal Skripsi LaTeX (Multi-Pass)"
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
