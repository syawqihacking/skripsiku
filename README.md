# Proposal Skripsi & Lingkungan Eksperimen

> **ANALISIS PERBANDINGAN KINERJA NGINX DAN HAPROXY SEBAGAI *LOAD BALANCER* PADA *WEB SERVICE* BERBASIS DOCKER DENGAN KAPASITAS *BACKEND* HETEROGEN**

[![LaTeX Document](https://img.shields.io/badge/LaTeX-TeX%20Live%202026-teal?logo=latex)](file:///home/acer/Desktop/skripsi-ku/main.pdf)
[![Docker](https://img.shields.io/badge/Docker-cgroups%20v2-blue?logo=docker)](file:///home/acer/Desktop/skripsi-ku/experiments/docker-compose.yml)
[![Grafana k6](https://img.shields.io/badge/Benchmark-Grafana%20k6-orange?logo=k6)](file:///home/acer/Desktop/skripsi-ku/experiments/benchmark/)
[![Golang](https://img.shields.io/badge/Backend-Go%201.22-00ADD8?logo=go)](file:///home/acer/Desktop/skripsi-ku/experiments/backend/)
[![FST UNIBA](https://img.shields.io/badge/FST-UNIBA%20Madura-green)](https://uniba-madura.ac.id)

---

## 1. Identitas Penelitian

| Atribut | Keterangan |
| :--- | :--- |
| **Peneliti** | **Ahmad Muqtafi** (NIM: `2302310264`) |
| **Program Studi** | S1 Informatika |
| **Fakultas / Universitas** | Fakultas Sains dan Teknologi, Universitas K.H. Bahaudin Mudhary Madura |
| **Bidang Minat** | Jaringan Komputer dan Sistem Terdistribusi |
| **Dosen Pembimbing I** | Prof. Dr. Ir. Rachmad Hidayat, M.T., IPU., ASEAN Eng. (NIP: 19740619.201808.1.010) |
| **Dosen Pembimbing II** | Akhmad Tajuddin Tholaby M.S., S.Kom., M.Kom. |
| **Ketua Program Studi** | Zeinor Rahman, S.Pd., M.Pd. (NIP: 19960306.202108.1.061) |
| **Tahun Akademik** | 2026 |

---

## 2. Ikhtisar Penelitian (*Research Overview*)

### 2.1 Latar Belakang & Masalah
Dalam arsitektur *microservices* modern berbasis kontainer Docker, lingkungan produksi sering kali beroperasi dalam kondisi kapasitas kluster yang **heterogen** (*asymmetric resource allocation*), baik karena strategi *instance tiering* (skema ukuran *t-shirt*), pembatasan kuota *kernel Control Groups* (cgroups), maupun alokasi sumber daya komputasi bertingkat. 

Penerapan *load balancer* tradisional yang mengasumsikan kapasitas peladen homogen (seperti algoritma *Round Robin* dan *Least Connections*) berpotensi menimbulkan:
1. **Ketimpangan Beban Kerja:** Node berkapasitas rendah kewalahan menangani antrean trafik soket.
2. ***CPU Throttling*: Peladen kehabisan jatah kuota *Complete Fair Scheduler* (CFS), memicu penurunan tajam pada *throughput*.
3. **Anomali Latensi Ekor (*Tail Latency*):** Lonjakan latensi pada persentil ekstrem ($p_{95}, p_{99}$) yang merusak Service Level Agreement (SLA).

### 2.2 Tujuan Penelitian
Melakukan pengujian empiris kuantitatif komparatif antara dua mesin *reverse proxy* terpopuler (**NGINX** dan **HAProxy**) dalam mendistribusikan beban pada kluster kontainer *backend* heterogen menggunakan 4 algoritma penjadwalan (*Round Robin*, *Least Connections*, *Weighted Round Robin*, dan *Weighted Least Connections*) di bawah 2 karakteristik beban kerja (*CPU-bound* dan *I/O-bound*).

### 2.3 Matriks 16 Skenario Pengujian
Penelitian mengeksekusi matriks kombinasi faktorial:
$$\{ \text{NGINX}, \text{HAProxy} \} \times \{ \text{RR}, \text{LC}, \text{WRR}, \text{WLC} \} \times \{ \text{CPU-bound}, \text{I/O-bound} \} = 16 \text{ Skenario}$$

### 2.4 Topologi Kluster Kontainer Heterogen (Rasio 1:2:4)
Kluster disimulasikan menggunakan alokasi cgroups pada berkas `experiments/docker-compose.yml`:

| Nama Kontainer | Kuota vCPU (`cpus`) | Batas Memori (`mem_limit`) | Rasio Kapasitas | Bobot Ideal ($w_i$) | Target Proporsi Trafik |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `web-backend-1` | 0.50 vCPU ($50.000\,\mu\text{s}$) | 256 MB | $1\times$ | $w_1 = 1$ | **14,29%** ($1/7$) |
| `web-backend-2` | 1.00 vCPU ($100.000\,\mu\text{s}$) | 512 MB | $2\times$ | $w_2 = 2$ | **28,57%** ($2/7$) |
| `web-backend-3` | 2.00 vCPU ($200.000\,\mu\text{s}$) | 1024 MB | $4\times$ | $w_3 = 4$ | **57,14%** ($4/7$) |

---

## 3. Struktur Repositori

```text
skripsi-ku/
├── main.tex                    # Dokumen utama LaTeX (driver)
├── main.pdf                    # Output terkompilasi proposal skripsi (PDF siap cetak)
├── compile.sh                  # Skrip otomatisasi build multi-pass & pembersihan berkas
├── Makefile                    # Makefile pembungkus perintah kompilasi
├── config/                     # Konfigurasi modular LaTeX
│   ├── formatting.tex          # Format margin 4-4-3-3, font Times 12pt, spasi 1.5, TOC/LOT/LOF
│   ├── metadata.tex            # Metadata dinamis: judul, nama, NIM, pembimbing, kaprodi
│   └── packages.tex            # Impor pustaka LaTeX (geometry, setspace, tikz, booktabs, dll.)
├── frontmatter/                # Halaman pembuka (penomoran romawi kecil)
│   ├── 00-cover.tex            # Sampul proposal skripsi sesuai pedoman FST 2026
│   ├── 01-pengesahan.tex       # Lembar persetujuan/pengesahan pembimbing & kaprodi
│   └── 02-kata-pengantar.tex   # Kata pengantar peneliti
├── chapters/                   # Batang tubuh dokumen skripsi
│   ├── bab1.tex                # BAB I: PENDAHULUAN (Latar Belakang s.d. Sistematika)
│   ├── bab2.tex                # BAB II: TINJAUAN PUSTAKA (Studi Terdahulu & Landasan Teori)
│   └── bab3.tex                # BAB III: METODOLOGI PENELITIAN (Topologi & Skenario)
├── appendices/                 # Bagian lampiran
│   └── lampiran.tex            # Lampiran kode sumber dan konfigurasi
├── references/                 # Manajemen sitasi & daftar pustaka
│   ├── apa-custom.bst          # Style BibTeX kustom APA Style FST UNIBA
│   └── daftar-pustaka.bib      # Database referensi ilmiah primer (DOI terverifikasi)
├── figures/                    # Berkas gambar dan diagram penelitian
│   └── logo-uniba.png          # Logo resmi universitas untuk halaman sampul
├── pedoman-dan-referensi/      # Dokumen rujukan resmi & contoh proposal yang telah di-ACC
│   ├── Panduan-TA-FST-2026.pdf
│   ├── referensi-proposal-temen-kelas-yang-sudah-sempro.pdf
│   └── skripsi-kating.pdf
└── experiments/                # Lingkungan implementasi & uji beban (Docker, k6, Go, scripts)
    ├── README.md               # Dokumentasi detail eksekusi eksperimen
    ├── docker-compose.yml      # Orkestrasi kluster (NGINX, HAProxy, 3 Backend, cAdvisor, k6)
    ├── backend/                # Layanan RESTful API Go (/api/cpu & /api/io)
    ├── benchmark/              # Skrip skenario pengujian beban Grafana k6 (100 - 1.000 VUs)
    ├── loadbalancer/           # Berkas konfigurasi proksi NGINX & HAProxy (RR, LC, WRR, WLC)
    └── scripts/                # Skrip eksekusi 16 skenario otomatis & parser audit log MAPE
```

---

## 4. Prasyarat & Instalasi Lingkungan LaTeX

Dokumen skripsi ini dibangun di atas sistem typesetting **LaTeX (TeX Live)** dengan standar format akademik FST UNIBA (Font *Times New Roman* / *TeX Gyre Termes*, margin 4-3-3-4 cm, spasi 1.5 baris).

### 4.1 Instalasi TeX Live pada Linux (Ubuntu / Debian)

Jalankan perintah berikut di terminal untuk memasang paket inti TeX Live, pengelola sitasi BibTeX, serta paket font yang dibutuhkan:

```bash
sudo apt update
sudo apt install -y \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-bibtex-extra \
    texlive-extra-utils \
    poppler-utils \
    build-essential
```

### 4.2 Verifikasi Pemasangan Utilitas

Pastikan perintah `pdflatex` dan `bibtex` telah terpasang dengan benar di sistem Anda:

```bash
pdflatex --version
bibtex --version
```

---

## 5. Panduan Kompilasi Dokumen Skripsi

Proyek ini menyediakan skrip otomasi [`compile.sh`](file:///home/acer/Desktop/skripsi-ku/compile.sh) dan [`Makefile`](file:///home/acer/Desktop/skripsi-ku/Makefile) untuk memudahkan siklus build dokumen.

### 5.1 Kompilasi Penuh (*Multi-Pass Build*)
Kompilasi penuh menjalankan 4 tahapan berurutan (*Pass 1: Indeks awal $\to$ Pass 2: BibTeX APA $\to$ Pass 3: Tautan sitasi $\to$ Pass 4: Finalisasi TOC, LOT, LOF*) guna memastikan seluruh referensi silang dan nomor halaman akurat:

```bash
# Menggunakan skrip shell:
./compile.sh

# Atau menggunakan Make:
make
```

### 5.2 Kompilasi Cepat (*Quick Single-Pass*)
Digunakan saat melakukan penulisan konten atau perbaikan teks biasa tanpa perubahan sitasi/struktur bab:

```bash
# Menggunakan skrip shell:
./compile.sh quick

# Atau menggunakan Make:
make quick
```

### 5.3 Pembersihan Berkas Sementara (*Clean Build Artifacts*)
Menghapus seluruh berkas sementara build LaTeX (`*.aux`, `*.bbl`, `*.blg`, `*.log`, `*.toc`, `*.lot`, `*.lof`, dll.) agar direktori kerja tetap bersih:

```bash
# Menggunakan skrip shell:
./compile.sh clean

# Atau menggunakan Make:
make clean
```

---

## 6. Panduan Alur Kerja Modular Penulisan

1. **Memperbarui Metadata Skripsi:**
   Seluruh data identitas dokumen terpusat di berkas [`config/metadata.tex`](file:///home/acer/Desktop/skripsi-ku/config/metadata.tex). Cukup ubah nilai macro (seperti `\skripsiJudul`, `\skripsiPenulis`, `\skripsiNIM`, atau nama dosen pembimbing), maka lembar sampul (*Cover*) dan lembar pengesahan akan otomatis tersinkronisasi.

2. **Menulis & Mengedit Bab:**
   Setiap bab disimpan secara terpisah di folder `chapters/`:
   - [`chapters/bab1.tex`](file:///home/acer/Desktop/skripsi-ku/chapters/bab1.tex): Pendahuluan, perumusan masalah, batasan masalah, dan sistematika.
   - [`chapters/bab2.tex`](file:///home/acer/Desktop/skripsi-ku/chapters/bab2.tex): Tinjauan pustaka, pemetaan 11 studi empiris sebelumnya, teori dasar, dan kerangka berpikir.
   - [`chapters/bab3.tex`](file:///home/acer/Desktop/skripsi-ku/chapters/bab3.tex): Metodologi penelitian, topologi kluster, desain workload, metrik evaluasi, dan instrumen.

3. **Menambahkan Referensi Pustaka (BibTeX):**
   - Tambahkan entri sitasi berformat BibTeX pada berkas [`references/daftar-pustaka.bib`](file:///home/acer/Desktop/skripsi-ku/references/daftar-pustaka.bib).
   - Sitasi di dalam naskah ditulis menggunakan perintah `\citep{kunci_sitasi}` atau `\citeauthor{kunci_sitasi}`.
   - Jalankan `./compile.sh` untuk menyegarkan daftar pustaka otomatis.

4. **Standar Format Tabel (Kotak Penuh / Grid):**
   Seluruh tabel menggunakan style kotak penuh (`|c|c|...|`) dengan header berlatar abu-abu (*shaded*) `\rowcolor{gray!15}` dan garis pemisah horizontal ganda `\hline\hline` untuk menjaga keseragaman format proposal.

---

## 7. Ekosistem Eksperimen & Uji Beban

Repositori ini memuat implementasi *environment* pengujian lengkap yang dapat direproduksi secara mandiri (*fully reproducible*) di dalam direktori [`experiments/`](file:///home/acer/Desktop/skripsi-ku/experiments/).

### 7.1 Menjalankan Kluster Kontainer (Docker Compose)
Kluster mendukung pemilihan profil aktif untuk NGINX atau HAProxy:

```bash
cd experiments/

# Menjalankan NGINX dengan profil WRR:
export NGINX_CONF="./loadbalancer/nginx/nginx-wrr.conf"
docker compose --profile nginx up -d --build

# Menjalankan HAProxy dengan profil WLC:
export HAPROXY_CONF="./loadbalancer/haproxy/haproxy-wlc.cfg"
docker compose --profile haproxy up -d --build
```

### 7.2 Eksekusi Uji Beban (Grafana k6)
Pengujian beban mensimulasikan trafik bertahap dari 100 hingga 1.000 pengguna virtual (*Virtual Users* / VUs):

```bash
# Menjalankan pengujian CPU-Bound:
k6 run benchmark/cpu-test.js

# Menjalankan pengujian I/O-Bound:
k6 run benchmark/io-test.js
```

### 7.3 Otomasi 16 Skenario Pengujian
Jalankan skrip otomasi pengujian dan kalkulasi metrik MAPE audit log:

```bash
# Sintaks: ./scripts/run-matrix.sh <load_balancer> <algoritma> <karakteristik_beban>
./scripts/run-matrix.sh nginx wrr cpu
./scripts/run-matrix.sh haproxy wlc io
```

> 📖 **Dokumentasi Lengkap Eksperimen:**  
> Silakan buka berkas [`experiments/README.md`](file:///home/acer/Desktop/skripsi-ku/experiments/README.md) untuk mempelajari arsitektur kode Go, konfigurasi proksi terperinci, instruksi cgroups, dan metodologi audit telemetri.

---

## 8. Lisensi & Hak Cipta

Naskah proposal skripsi dan kode konfigurasi pengujian ini dikembangkan untuk keperluan akademik di **Program Studi Informatika, Fakultas Sains dan Teknologi, Universitas K.H. Bahaudin Mudhary Madura**. Hak cipta penulisan naskah dilindungi oleh undang-undang, sedangkan skrip pengujian dirilis di bawah lisensi terbuka [MIT License](https://opensource.org/licenses/MIT).
