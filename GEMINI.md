# Panduan & Standar Penulisan Skripsi (Antigravity Workspace Rules)
**Program Studi Informatika — Fakultas Sains dan Teknologi**  
**Universitas K.H. Bahaudin Mudhary Madura**

File ini berisi aturan permanen yang wajib ditaati oleh Agent saat membaca, meninjau, menyusun, maupun mengedit dokumen skripsi ini.

---

## 1. Tata Bahasa & Gaya Penulisan Ilmiah
1. **Ragam Formal & Objektif**: Gunakan bahasa Indonesia baku sesuai kaidah EYD/PUEBI dan tata bahasa akademik resmi.
2. **Sudut Pandang**: Jangan pernah menggunakan kata ganti orang pertama seperti "saya", "aku", "kami", atau "kita". Selalu gunakan sebutan **"penulis"** atau gunakan kalimat pasif ilmiah (misal: *"Analisis dilakukan dengan..."*).
3. **Istilah Asing / Komputasi**:
   - Seluruh istilah teknis komputasi, istilah jaringan, dan kata bahasa asing wajib dicetak miring menggunakan `\textit{...}` (contoh: `\textit{load balancer}`, `\textit{throughput}`, `\textit{tail latency}`, `\textit{microservices}`, `\textit{backend}`).
   - Penulisan akronim atau singkatan pada kemunculan pertama wajib dieja lengkap disertai singkatan di dalam kurung, misalnya: *Control Groups* (cgroups), *Virtual Machine* (VM), *Completely Fair Scheduler* (CFS).

---

## 2. Format Sitasi & Daftar Pustaka (APA Style)
1. **Pustaka BibTeX**: Seluruh referensi wajib didaftarkan di `references/daftar-pustaka.bib`. Jangan menulis sitasi manual di teks tanpa entri BibTeX.
2. **Kaidah Pemanggilan Sitasi**:
   - Gunakan `\citep{key}` untuk sitasi dalam kurung di akhir argumen/kalimat, misal: `\citep{merkel2014docker}` $\rightarrow$ *(Merkel, 2014)*.
   - Gunakan `\citet{key}` untuk sitasi yang menjadi subjek kalimat, misal: `\citet{turner2010cpu} menyatakan bahwa...` $\rightarrow$ *Turner et al. (2010) menyatakan bahwa...*.
3. **Kemutakhiran Pustaka**: Pustaka yang digunakan diutamakan terbit dalam 10 tahun terakhir (maksimal 20% untuk pustaka klasik/dasar teori lama).

---

## 3. Rujukan Objek Dokumen (Cross-Referencing)
1. **Tabel & Gambar**:
   - Selalu rujuk menggunakan makro bahasa: `\tablename~\ref{tab:label}` dan `\figurename~\ref{fig:label}`.
   - Jangan pernah menggunakan frasa relatif seperti "tabel di bawah", "gambar di atas", atau "pada bagan berikut".
2. **Persamaan Matematika**:
   - Rujuk persamaan menggunakan `\eqref{eq:label}` atau `Persamaan~\eqref{eq:label}`.
3. **Format Caption**:
   - Tabel: `\caption{...}` diletakkan di **atas** tabel.
   - Gambar: `\caption{...}` diletakkan di **bawah** gambar.
   - Judul tabel dan gambar tidak diakhiri tanda titik `.`.

---

## 4. Integritas Struktur & Spasi LaTeX
1. **Pertahankan Konfigurasi Dokumen**: Jangan mengubah pengaturan pada `main.tex`, `config/formatting.tex`, atau `config/packages.tex` kecuali diminta secara eksplisit oleh pengguna.
2. **Spasi Daftar (`enumerate` & `itemize`)**:
   - Lingkungan daftar telah dikonfigurasi menggunakan paket `enumitem` dengan opsi `nosep` (tanpa *space after* antar-butir). Pertahankan struktur `\begin{enumerate} ... \end{enumerate}` standar tanpa menambahkan `\vspace` manual.
3. **Verifikasi Kompilasi**:
   - Setiap kali selesai memodifikasi teks pada berkas `chapters/*.tex` atau `frontmatter/*.tex`, jalankan skrip `./compile.sh quick` untuk memastikan tidak ada kesalahan kompilasi (*fatal error* atau *broken references*).
