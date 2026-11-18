---
name: skripsi-guide
description: >-
  Panduan dan prosedur penulisan skripsi/proposal Program Studi Informatika
  Fakultas Sains dan Teknologi Universitas K.H. Bahaudin Mudhary Madura.
  Gunakan skill ini saat menyusun, mengembangkan, atau merevisi bab skripsi (Bab I, II, III, IV, V).
---

# Panduan Penulisan Skripsi Informatika UNIBA Madura

Skill ini memuat pedoman resmi penulisan skripsi berbasis LaTeX untuk Program Studi Informatika, Fakultas Sains dan Teknologi, Universitas K.H. Bahaudin Mudhary Madura.

## 1. Struktur Bab & Standar Konten

### Bab I: Pendahuluan
- **1.1 Latar Belakang**:
  - Pola piramida terbalik: Masalah makro (tren industri/teknologi) $\rightarrow$ Masalah meso (*gap* riset/keterbatasan sistem) $\rightarrow$ Masalah mikro (solusi yang diajukan).
  - Wajib menyertakan fakta/data kuantitatif awal dan rujukan penelitian relevan terdahulu.
- **1.2 Rumusan Masalah**:
  - Pertanyaan penelitian (*research questions*) yang spesifik, terukur, dan menjawab *gap* di latar belakang.
- **1.3 Batasan Masalah**:
  - Ruang lingkup eksperimen (misal: versi Docker/OS, spesifikasi perangkat, batas algoritma yang diuji).
- **1.4 Tujuan Penelitian**:
  - Selaras 1-to-1 dengan rumusan masalah. Menggunakan kata kerja operasional (misal: "Menganalisis", "Mengimplementasikan", "Mengkomparasikan").
- **1.5 Manfaat Penelitian**:
  - Manfaat teoritis (akademis) dan manfaat praktis (industri/organisasi).

### Bab II: Tinjauan Pustaka & Landasan Teori
- **2.1 Penelitian Terdahulu**:
  - Minimal 5–10 referensi jurnal/konferensi bereputasi (5–10 tahun terakhir).
  - Memuat **Tabel State-of-the-Art** yang membandingkan: Peneliti, Judul/Tahun, Metode, Variabel, dan Perbedaan/Keterbaruan dengan penelitian ini.
- **2.2 Landasan Teori**:
  - Hanya memuat teori yang langsung dipakai dalam perancangan dan pengujian sistem.
  - Hindari definisi kamus umum yang tidak esensial.

### Bab III: Metodologi Penelitian
- **3.1 Alur Penelitian**:
  - Diagram alir penelitian (*flowchart*) yang jelas dan deskripsi tahapan dari inisiasi sampai evaluasi.
- **3.2 Lingkungan & Instrumen Eksperimen**:
  - Spesifikasi *hardware*, *software*, topologi jaringan, skenario beban (*workload*).
- **3.3 Parameter & Metrik Pengujian**:
  - Metrik evaluasi yang terdefinisi matematis (misal: *throughput*, *response time*, *error rate*, *resource utilization*).

---

## 2. Standar Tipografi & Kaidah Bahasa

1. **Tata Bahasa Akademik**:
   - Bahasa Indonesia baku (EYD/PUEBI).
   - Sudut pandang orang ketiga pasif atau menggunakan frasa **"penulis"**. Jangan gunakan kata "saya", "kami", atau "kita".
2. **Istilah Teknis Asing**:
   - Semua istilah asing/komputasi wajib dicetak miring dengan `\textit{...}` (misal: `\textit{round-robin}`, `\textit{benchmark}`, `\textit{containerization}`).
3. **Sitasi & Daftar Pustaka**:
   - Wajib menggunakan BibTeX format APA 7th edition (`apacite` / `natbib`).
   - `\citep{key}` untuk sitasi di akhir kalimat: *(Merkel, 2014)*.
   - `\citet{key}` untuk sitasi integratif: *Merkel (2014) mengemukakan...*.
4. **Perujukan Gambar & Tabel**:
   - Selalu gunakan `\figurename~\ref{fig:label}` dan `\tablename~\ref{tab:label}`.
   - Caption tabel di atas tabel; caption gambar di bawah gambar.
   - Tanpa titik di akhir judul caption.

---

## 3. Alur Kerja Kompilasi
Gunakan skrip pembantu untuk menguji perubahan:
- Kompilasi cepat (1 pass): `./compile.sh quick`
- Kompilasi penuh (4 pass + BibTeX): `./compile.sh`
- Bersihkan file *auxiliary*: `./compile.sh clean`
