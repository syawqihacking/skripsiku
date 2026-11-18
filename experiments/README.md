# Panduan Repositori Eksperimen & Pengujian Beban Skripsi

**Judul Penelitian:**
> *Analisis Perbandingan Kinerja NGINX dan HAProxy sebagai Load Balancer pada Web Service Berbasis Docker dengan Kapasitas Backend Heterogen*

* **Peneliti:** Ahmad Muqtafi (NIM: 2302310264)
* **Program Studi:** S1 Informatika — Fakultas Sains dan Teknologi, Universitas K.H. Bahaudin Mudhary Madura (2026)
* **Target Infrastruktur:** Laptop *Bare-Metal* MSI Thin GF63 12UCX (Ubuntu 24.04 LTS) & Kluster Docker Kontainer

---

## Daftar Isi
1. [Struktur Direktori Proyek](#1-struktur-direktori-proyek)
2. [Spesifikasi Lingkungan & Arsitektur Sistem](#2-spesifikasi-lingkungan--arsitektur-sistem)
3. [Prasyarat & Persiapan Awal (Prerequisites)](#3-prasyarat--persiapan-awal-prerequisites)
4. [Tuning Kernel Linux Host (sysctl)](#4-tuning-kernel-linux-host-sysctl)
5. [Alur Pelaksanaan Eksperimen](#5-alur-pelaksanaan-eksperimen)
   * [Langkah 1: Verifikasi Kluster Kontainer Docker](#langkah-1-verifikasi-kluster-kontainer-docker)
   * [Langkah 2: Menjalankan Pengujian Beban (Grafana k6)](#langkah-2-menjalankan-pengujian-beban-grafana-k6)
   * [Langkah 3: Menjalankan Matriks Lengkap (16 Skenario x 3 Replikasi)](#langkah-3-menjalankan-matriks-lengkap-16-skenario-x-3-replikasi)
   * [Langkah 4: Audit Distribusi Beban & Kalkulasi MAPE](#langkah-4-audit-distribusi-beban--kalkulasi-mape)
6. [Pemantauan Telemetri Real-Time](#6-pemantauan-telemetri-real-time)
7. [Tabel Rujukan Dokumentasi Resmi](#7-tabel-rujukan-dokumentasi-resmi)
8. [Panduan Pemecahan Masalah (Troubleshooting FAQ)](#8-panduan-pemecahan-masalah-troubleshooting-faq)

---

## 1. Struktur Direktori Proyek

```text
experiments/
├── backend/                  # Layanan Web Service berbasis Golang
│   ├── Dockerfile            # Multi-stage build image ultra-ringan (< 15 MB)
│   ├── go.mod                # Modul dependensi Go
│   └── main.go               # Implementasi endpoint /api/cpu & /api/io
├── benchmark/                # Skenario Pengujian Beban Stres Grafana k6
│   ├── cpu-test.js           # Uji beban bertahap (100 -> 500 -> 1.000 VUs) untuk CPU-bound
│   └── io-test.js            # Uji beban bertahap untuk I/O-bound (antrean soket terbuka)
├── loadbalancer/             # Berkas Konfigurasi Mesin Penyeimbang Beban
│   ├── haproxy/              # Konfigurasi HAProxy (RR, LC, WRR, WLC)
│   │   ├── haproxy-lc.cfg
│   │   ├── haproxy-rr.cfg
│   │   ├── haproxy-wlc.cfg
│   │   └── haproxy-wrr.cfg
│   └── nginx/                # Konfigurasi NGINX (RR, LC, WRR, WLC)
│       ├── nginx-lc.conf
│       ├── nginx-rr.conf
│       ├── nginx-wlc.conf
│       └── nginx-wrr.conf
├── scripts/                  # Otomasi Orkestrasi & Analisis Data
│   ├── parse-logs.py         # Penghitung presisi distribusi beban & metrik MAPE
│   ├── run-matrix.sh         # Eksekutor otomatis 16 skenario matriks dengan CPU pinning
│   └── tune-sysctl.sh        # Skrip sakelar (toggle switch) tuning kernel Linux (on/off/status)
├── docker-compose.yml        # Orkestrasi kluster kontainer heterogen (rasio kuota 1:2:4, cpuset P-cores)
└── README.md                 # Dokumentasi panduan operasional eksperimen
```

---

## 2. Spesifikasi Lingkungan & Arsitektur Sistem

Eksperimen diselenggarakan pada lingkungan komputasi *bare-metal* lokal laptop **MSI Thin GF63 12UCX** dengan partisi sistem operasi mandiri (Ubuntu 24.04 LTS).

### 2.1 Spesifikasi Perangkat Keras & Perangkat Lunak Host
| Parameter | Spesifikasi Rinci |
| :--- | :--- |
| **Model Perangkat** | MSI Thin GF63 12UCX (*Dual-boot Setup*) |
| **Prosesor (CPU)** | Intel® Core™ i5-12450H (Alder Lake-H, 8 Cores / 12 Threads) |
| **Konfigurasi Core** | 4 *Performance-cores* (4.40 GHz) + 4 *Efficient-cores* (3.30 GHz) |
| **Cache CPU** | 12 MB Intel® Smart Cache |
| **Memori RAM** | 16 GB DDR4 3200 MHz |
| **Penyimpanan** | NVMe PCIe SSD (Alokasi 100 GB untuk Root Partisi Ubuntu) |
| **Sistem Operasi** | Ubuntu 24.04 LTS (*Noble Numbat*, Kernel Linux 6.8+) |
| **Runtime Kontainer** | Docker Engine v27.x & Docker Compose v2.x |
| **Load Generator** | Grafana k6 v0.50+ |
| **Bahasa Scripting** | Python 3.12 (NumPy, Pandas) & Bash |

### 2.2 Strategi Isolasi Sumber Daya (CPU Affinity & Pinning)
Untuk mencegah perebutan siklus CPU (*resource contention*) dan menjaga validitas data empiris pada arsitektur prosesor hibrida Intel Generasi ke-12:
1. **Domain Peladen & Kluster Docker**: Dibatasi secara ketat pada **P-Cores (CPU 0–7)** melalui pengaturan `cpuset: "0-7"` pada berkas `docker-compose.yml`. Karakteristik P-core yang memiliki IPC tinggi dan frekuensi clock identik memastikan alokasi kuota cgroups v2 (`0.50`, `1.00`, `2.00` vCPU) dievaluasi pada basis komputasi yang seragam.
2. **Domain Pembangkit Beban (Grafana k6)**: Diisolasi secara eksklusif pada **E-Cores (CPU 8–11)** menggunakan instruksi Linux `taskset -c 8-11`. Pembangkitan beban hingga 1.000 VUs berjalan secara terpisah tanpa mengurangi siklus eksekusi kontainer *backend* maupun *load balancer*.
3. **Jaringan Internal**: Komunikasi antar k6 dan *load balancer* melalui *host network stack* (`http://127.0.0.1:80`), sedangkan komunikasi *load balancer* ke *backend* menggunakan *bridge network* privat Docker `skripsi-net` (`172.28.0.0/16`).

### 2.3 Alokasi Kuota Kontainer Backend Heterogen (Rasio 1:2:4)
| Kontainer | Tingkatan (*Tier*) | Alokasi CPU (`cpus`) | Batas Memori (`mem_limit`) | Rasio Kapasitas | Bobot Ideal ($w_i$) |
| :--- | :--- | :---: | :---: | :---: | :---: |
| `web-backend-1` | *Small* | 0.50 vCPU | 256 MB | 1 | 1 |
| `web-backend-2` | *Medium* | 1.00 vCPU | 512 MB | 2 | 2 |
| `web-backend-3` | *Large* | 2.00 vCPU | 1024 MB | 4 | 4 |

---

## 3. Prasyarat & Persiapan Awal (Prerequisites)

Pastikan paket-paket berikut telah terinstal pada Ubuntu 24.04 LTS Anda:

### 3.1 Instalasi Docker & Docker Compose
```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Tambahkan GPG key resmi Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Tambahkan repositori Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Izinkan pengguna non-root mengeksekusi Docker
sudo usermod -aG docker $USER
```
*(Setelah menjalankan perintah di atas, lakukan *log out* lalu *log in* kembali agar grup Docker aktif).*

### 3.2 Instalasi Grafana k6
```bash
# Unduh kunci resmi k6 via HTTPS dan simpan ke keyring
curl -fsSL https://dl.k6.io/key.gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/k6-archive-keyring.gpg
sudo chmod a+r /usr/share/keyrings/k6-archive-keyring.gpg

# Daftarkan repositori k6
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list

# Update indeks paket dan pasang k6
sudo apt update
sudo apt install -y k6
```

### 3.3 Instalasi Dependensi Python & Virtual Environment
Untuk menghindari konflik paket sistem (PEP 668), gunakan *Python Virtual Environment* (`.venv`) di dalam direktori `experiments/`:
```bash
# Pasang dependensi dasar dan venv
sudo apt install -y python3 python3-pip python3-venv util-linux

# Buat virtual environment dan aktifkan
cd /home/muqtafi/Desktop/my-project/skripsi-ku/experiments
python3 -m venv .venv
source .venv/bin/activate

# Pasang modul komputasi dan visualisasi data
pip install --upgrade pip
pip install numpy pandas scipy matplotlib
```

---

## 4. Tuning Kernel Linux Host (sysctl)

Beban uji hingga 1.000 VUs menghasilkan puluhan ribu *socket connection* per detik. Tanpa tuning, kernel Linux akan mengalami *TCP socket exhaustion*, antrean *SYN backlog overflow*, atau penolakan koneksi (*connection refused*).

Telah disediakan skrip otomatisasi sakelar (**[scripts/tune-sysctl.sh](file:///home/muqtafi/Desktop/my-project/skripsi-ku/experiments/scripts/tune-sysctl.sh)**) agar laptop dapat dialihkan ke mode pengujian beban tinggi dan dikembalikan ke konfigurasi bawaan (*default*) Ubuntu saat Anda mengerjakan proyek lain:

```bash
cd /home/muqtafi/Desktop/my-project/skripsi-ku/experiments

# 1. Periksa status konfigurasi kernel saat ini:
./scripts/tune-sysctl.sh status

# 2. Aktifkan konfigurasi kapasitas tinggi sebelum eksperimen:
sudo ./scripts/tune-sysctl.sh on

# 3. Kembalikan ke pengaturan default murni Ubuntu 24.04 (setelah eksperimen selesai):
sudo ./scripts/tune-sysctl.sh off
```

> **Catatan Parameter Tuning (`on`):**
> * `net.core.somaxconn = 65535` : Memperbesar antrean soket *listen* dari bawaan 4096.
> * `net.ipv4.tcp_max_syn_backlog = 65535` : Menampung lonjakan *handshake* SYN dari ribuan koneksi k6.
> * `net.ipv4.ip_local_port_range = 1024 65535` : Memperluas jangkauan *ephemeral port* keluar.
> * `net.ipv4.tcp_tw_reuse = 1` : Mengizinkan daur ulang soket `TIME_WAIT` secara aman.
> * `net.ipv4.tcp_fin_timeout = 15` : Mempercepat pelepasan soket pasca-*close* (bawaan: 60 detik).

---

## 5. Alur Pelaksanaan Eksperimen

Masuk ke direktori `experiments/` dan pastikan izin eksekusi skrip aktif:
```bash
cd /home/muqtafi/Desktop/my-project/skripsi-ku/experiments
chmod +x scripts/*.sh

# Aktifkan virtual environment Python & tuning kernel
source .venv/bin/activate
sudo ./scripts/tune-sysctl.sh on
```

### Langkah 1: Verifikasi Kluster Kontainer Docker
Uji kesiapan kluster secara manual menggunakan profil NGINX:
```bash
# Jalankan NGINX dengan algoritma WRR
export NGINX_CONF="./loadbalancer/nginx/nginx-wrr.conf"
docker compose --profile nginx up -d --build

# Periksa status seluruh kontainer
docker compose ps
```
Pastikan seluruh layanan (`web-backend-1`, `web-backend-2`, `web-backend-3`, `lb-nginx`) berstatus `Up`.

Lakukan uji coba pemanggilan HTTP:
```bash
curl -i http://localhost/health
curl -i http://localhost/api/cpu
curl -i http://localhost/api/io
```

### Langkah 2: Menjalankan Pengujian Beban (Grafana k6)
Jalankan satu skenario uji beban menggunakan skrip matriks otomatis:
```bash
# Sintaks: ./scripts/run-matrix.sh <lb> <algo> <workload> [--quick]
# Contoh Uji Cepat (1 menit, 50 VUs untuk kalibrasi):
./scripts/run-matrix.sh nginx wrr cpu --quick

# Contoh Uji Beban Penuh Skripsi (10 menit, 100 s.d. 1.000 VUs):
./scripts/run-matrix.sh nginx wrr cpu
```

### Langkah 3: Menjalankan Matriks Lengkap (16 Skenario x 3 Replikasi)
Untuk menghasilkan data empiris lengkap skripsi secara otomatis:
```bash
# Jalankan seluruh 16 skenario x 3 replikasi (Total 48 pengujian):
./scripts/run-matrix.sh all

# Atau uji cepat seluruh matriks (1 menit per skenario, 1 replikasi):
./scripts/run-matrix.sh all --quick
```

### Langkah 4: Audit Distribusi Beban & Kalkulasi MAPE
Setiap kali pengujian selesai, skrip otomatis memanggil parser log. Anda juga dapat menjalankannya secara mandiri:
```bash
# Untuk NGINX (Algoritma berbobot WRR/WLC):
python3 scripts/parse-logs.py --log logs/nginx/access.log --type nginx --algorithm weighted

# Untuk HAProxy (Algoritma tanpa bobot RR/LC):
python3 scripts/parse-logs.py --log logs/haproxy/haproxy.log --type haproxy --algorithm unweighted
```

---

## 6. Pemantauan Telemetri Real-Time

Selama pengujian berlangsung, Anda dapat memantau telemetri metrik internal melalui *web browser*:
* **cAdvisor Dashboard (Utilisasi CPU cgroups & Memori):**  
  Akses: `http://localhost:8081`
* **HAProxy Stats Dashboard (Statistik Antrean & Sesi Aktif):**  
  Akses: `http://localhost:8404` (Username: `admin`, Password: `adminpassword`)
* **Pemantauan Core CPU Host:**
  ```bash
  htop
  ```
  *(Perhatikan bahwa CPU 0–7 dialokasikan untuk Docker, sedangkan CPU 8–11 digunakan oleh k6).*

---

## 7. Tabel Rujukan Dokumentasi Resmi

| Komponen | Versi | Dokumentasi Resmi |
| :--- | :--- | :--- |
| **Docker Compose Resource Limits** | v2.x | [Docker Docs: Compose Resource Allocation](https://docs.docker.com/compose/compose-file/deploy/#resources) |
| **Linux CPU Affinity (taskset)** | Linux Man Pages | [taskset(1) — Linux manual page](https://man7.org/linux/man-pages/man1/taskset.1.html) |
| **Control Groups v2 (cgroups)** | Linux Kernel 6.x | [Kernel Docs: Control Group v2](https://docs.kernel.org/admin-guide/cgroup-v2.html) |
| **Grafana k6 Scenarios** | v0.50+ | [Grafana k6 Documentation: Scenarios](https://k6.io/docs/using-k6/scenarios/) |
| **NGINX HTTP Upstream Module** | 1.27 Mainline | [NGINX Docs: ngx_http_upstream_module](https://nginx.org/en/docs/http/ngx_http_upstream_module.html) |
| **HAProxy Configuration Guide** | 2.8 LTS | [HAProxy Documentation: Configuration Manual](https://docs.haproxy.org/2.8/configuration.html) |

---

## 8. Panduan Pemecahan Masalah (Troubleshooting FAQ)

### T: Mengapa k6 menampilkan error `dial tcp 127.0.0.1:80: connect: cannot assign requested address`?
**J:** Sistem kehabisan *ephemeral ports* lokal karena ribuan koneksi ditutup secara cepat dalam keadaan `TIME_WAIT`. Pastikan langkah tuning kernel pada [Bagian 4](#4-tuning-kernel-linux-host-sysctl) telah dijalankan, khususnya parameter `net.ipv4.tcp_tw_reuse = 1` dan `net.ipv4.ip_local_port_range = 1024 65535`.

### T: Mengapa `taskset` menampilkan error `failed to set pid's affinity: Invalid argument`?
**J:** Hal ini terjadi jika argumen core (CPU 8–11) melebihi jumlah logical core CPU yang tersedia di host. Skrip `run-matrix.sh` telah dilengkapi auto-fallback yang mendeteksi jumlah core secara dinamis. Pastikan pengujian final dijalankan pada laptop MSI GF63 12UCX (Intel Core i5-12450H yang memiliki 12 logical threads).

### T: Bagaimana cara membersihkan seluruh kontainer dan volume setelah eksperimen selesai?
**J:** Jalankan perintah pembersihan Docker Compose:
```bash
docker compose --profile nginx down --volumes --remove-orphans
docker compose --profile haproxy down --volumes --remove-orphans
```
