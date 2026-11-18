#!/usr/bin/env bash
# ==============================================================================
# AUTOMATED MATRIX TEST RUNNER (SKRIPSI AHMAD MUQTAFI)
# Lingkungan: Bare-Metal Laptop MSI Thin GF63 12UCX (Ubuntu 24.04 LTS)
# Isolasi CPU: Server pada P-Cores (0-7), k6 pada E-Cores (8-11)
# NGINX vs HAProxy x (RR, LC, WRR, WLC) x (CPU-bound, I/O-bound)
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
cd "$DIR"

mkdir -p logs/nginx logs/haproxy results

echo "=========================================================="
echo "SKRIPSI MATRIKS RUNNER: NGINX vs HAPROXY (DOCKER HETEROGEN)"
echo "Target Host: MSI Thin GF63 12UCX (Intel Core i5-12450H)"
echo "=========================================================="

# Deteksi ketersediaan core CPU untuk taskset E-Cores (CPU 8-11)
TOTAL_CPUS=$(nproc 2>/dev/null || echo 1)
TASKSET_CMD=""
if [ "$TOTAL_CPUS" -ge 12 ]; then
    TASKSET_CMD="taskset -c 8-11"
    echo "[ISOLASI CPU] Grafana k6 dipin ke E-Cores (CPU 8-11) via taskset."
else
    echo "[INFO] Sistem mendeteksi $TOTAL_CPUS CPU. taskset E-cores (8-11) dilewati pada lingkungan dev ini."
fi

run_scenario() {
    local lb="$1"       # nginx / haproxy
    local algo="$2"     # rr / lc / wrr / wlc
    local workload="$3" # cpu / io
    local quick_flag="$4" # --quick (opsional)

    echo ""
    echo ">>> MENJALANKAN SKENARIO: LB=$lb | ALGO=$algo | WORKLOAD=$workload <<<"
    echo "----------------------------------------------------------"

    # Reset logs
    rm -f logs/nginx/access.log logs/haproxy/haproxy.log

    # Setup environment variable konfigurasi
    if [ "$lb" == "nginx" ]; then
        export NGINX_CONF="./loadbalancer/nginx/nginx-${algo}.conf"
        docker compose --profile nginx down --volumes --remove-orphans > /dev/null 2>&1 || true
        docker compose --profile nginx up -d --build
        sleep 5
    else
        export HAPROXY_CONF="./loadbalancer/haproxy/haproxy-${algo}.cfg"
        docker compose --profile haproxy down --volumes --remove-orphans > /dev/null 2>&1 || true
        docker compose --profile haproxy up -d --build
        sleep 5
    fi

    echo "Status kluster aktif:"
    docker compose ps

    # Eksekusi k6
    local script="benchmark/${workload}-test.js"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_json="results/${lb}_${algo}_${workload}_${timestamp}.json"
    echo "Memulai uji beban Grafana k6 menggunakan $script..."

    local k6_extra_args=""
    if [ "$quick_flag" == "--quick" ]; then
        echo "[MODE CEPAT AKTIF] Menguji selama 1 menit (50 VUs) untuk kalibrasi."
        k6_extra_args="--vus 50 --duration 1m"
    fi

    if command -v k6 &> /dev/null; then
        $TASKSET_CMD k6 run $k6_extra_args --out json="$output_json" "$script"
    else
        echo "[WARNING] Grafana k6 tidak ditemukan di host. Menjalankan via Docker k6 runner..."
        docker run --rm -i --network="host" --cpuset-cpus="8-11" \
            -v "$DIR/benchmark:/benchmark" grafana/k6 run $k6_extra_args "/$script"
    fi

    # Audit proporsi log (MAPE)
    echo "Menjalankan audit presisi distribusi beban aktual (MAPE)..."
    local algo_type="weighted"
    if [ "$algo" == "rr" ] || [ "$algo" == "lc" ]; then
        algo_type="unweighted"
    fi

    if [ "$lb" == "nginx" ]; then
        if [ -f logs/nginx/access.log ]; then
            python3 scripts/parse-logs.py --log logs/nginx/access.log --type nginx --algorithm "$algo_type" || true
        fi
    else
        if [ -f logs/haproxy/haproxy.log ]; then
            python3 scripts/parse-logs.py --log logs/haproxy/haproxy.log --type haproxy --algorithm "$algo_type" || true
        fi
    fi

    echo "Skenario $lb-$algo-$workload selesai dieksekusi."
    echo "=========================================================="
}

run_all_matrix() {
    local quick_flag="$1"
    local replications=3
    if [ "$quick_flag" == "--quick" ]; then
        replications=1
    fi

    echo "MEMULAI EKSEKUSI MATRIKS PENUH (16 SKENARIO x $replications REPLIKASI)"
    local count=1
    local total=$(( 16 * replications ))

    for rep in $(seq 1 $replications); do
        echo "=========================================================="
        echo ">>> REPLIKASI KE-$rep DARI $replications <<<"
        echo "=========================================================="
        for lb in nginx haproxy; do
            for algo in rr lc wrr wlc; do
                for workload in cpu io; do
                    echo "[PROGRESS: $count / $total] Menjalankan $lb - $algo - $workload (Rep $rep)..."
                    run_scenario "$lb" "$algo" "$workload" "$quick_flag"
                    count=$((count + 1))
                    echo "Pendinginan singkat 10 detik antar-skenario..."
                    sleep 10
                done
            done
        done
    done
    echo "Seluruh matriks eksperimen selesai dieksekusi!"
}

# Parsing Argumen
if [ "$1" == "all" ]; then
    run_all_matrix "$2"
elif [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]; then
    run_scenario "$1" "$2" "$3" "$4"
else
    echo "Penggunaan:"
    echo "  Skenario Tunggal : ./scripts/run-matrix.sh <lb> <algo> <workload> [--quick]"
    echo "  Matriks Lengkap  : ./scripts/run-matrix.sh all [--quick]"
    echo ""
    echo "Contoh:"
    echo "  ./scripts/run-matrix.sh nginx wrr cpu"
    echo "  ./scripts/run-matrix.sh haproxy wlc io --quick"
    echo "  ./scripts/run-matrix.sh all --quick"
fi
