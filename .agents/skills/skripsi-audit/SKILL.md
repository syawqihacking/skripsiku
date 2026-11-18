---
name: skripsi-audit
description: >-
  Prosedur audit komprehensif format, kepatuhan tata letak, margin, spasi,
  sitasi APA, dan tipografi skripsi Universitas K.H. Bahaudin Mudhary Madura.
  Gunakan skill ini saat diminta melakukan pengecekan, review dokumen, atau audit kelayakan naskah.
---

# Prosedur Audit Format Skripsi UNIBA Madura

Skill ini menyediakan checklist dan prosedur audit kepatuhan format naskah skripsi berdasarkan pedoman FST 2026 dan komparasi dengan naskah acuan.

## Checklist 8 Pilar Audit

| No | Komponen Audit | Standar Wajib | Lokasi Konfigurasi / Berkas |
|---|---|---|---|
| 1 | **Margin Kertas** | Kiri: 4.0 cm, Atas/Kanan/Bawah: 3.0 cm | `config/formatting.tex` (`geometry`) |
| 2 | **Margin Atas BAB** | Tepat 3.0 cm (komparasi Word) | `config/formatting.tex` (`\titlespacing*{\chapter}{0pt}{-35pt}{...}`) |
| 3 | **Spasi Teks** | 1.5 baris (*one and a half*) | `config/formatting.tex` (`\onehalfspacing`) |
| 4 | **Space After Paragraf** | 0 pt (tidak ada spasi ekstra antar-paragraf) | `config/formatting.tex` (`\parskip=0pt`, `\raggedbottom`) |
| 5 | **Spasi Butir Daftar** | Rapat tanpa *space after* antar-butir | `config/formatting.tex` (`\setlist{nosep, leftmargin=0.75cm, labelsep=0.25cm}`) |
| 6 | **Jenis & Ukuran Font** | Times New Roman 12pt (Judul cover 14-16pt bold) | `config/packages.tex` (`times`, `ptm`) |
| 7 | **Tata Bahasa & Istilah** | PUEBI baku, sudut pandang orang ketiga, istilah asing `\textit{...}` | Naskah bab di `chapters/*.tex` |
| 8 | **Sitasi & Pustaka** | APA 7th edition, valid BibTeX, `\citep{}` & `\citet{}` | `references/daftar-pustaka.bib` |

---

## Prosedur Audit Mandiri

1. **Audit Bebas Kesalahan Kompilasi**:
   Jalankan `./compile.sh` dan verifikasi log tidak mengandung `Fatal error` atau `Emergency stop`.

2. **Audit Referensi Rusak / Tanda Tanya `[?]`**:
   Periksa kemunculan referensi yang belum terdefinisi:
   ```bash
   grep -i "citation .* undefined" main.log || echo "Semua sitasi terdaftar."
   grep -i "reference .* undefined" main.log || echo "Semua label rujukan valid."
   ```

3. **Audit Istilah Asing Belum Miring**:
   Pindai kata-kata teknis bahasa Inggris yang umum terlewatkan (misal: *docker, container, cluster, load balancing, throughput, latency, thread, microservice*) yang belum dibungkus `\textit{...}`.

4. **Verifikasi Visual Halaman Rendered**:
   Gunakan alat `pdftoppm` untuk merender halaman tertentu ke PNG jika perlu memverifikasi kerapian tata letak:
   ```bash
   pdftoppm -png -r 150 -f <no_hal> -l <no_hal> main.pdf page_preview
   ```
