#!/usr/bin/env bash
# ==============================================================================
# SYSCTL TUNING TOGGLE SCRIPT (SKRIPSI AHMAD MUQTAFI)
# Mengaktifkan/menonaktifkan tuning kernel Linux untuk eksperimen beban tinggi
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ] && [ "$1" != "status" ]; then
    echo "[-] Perintah ini memerlukan hak akses root/sudo."
    echo "    Contoh penggunaan: sudo $0 on | off | status"
    exit 1
fi

show_status() {
    echo "=== STATUS PENGATURAN KERNEL SAAT INI ==="
    sysctl net.core.somaxconn \
           net.ipv4.tcp_max_syn_backlog \
           net.ipv4.ip_local_port_range \
           net.ipv4.tcp_tw_reuse \
           net.ipv4.tcp_fin_timeout
}

case "$1" in
    on)
        echo "[+] Mengaktifkan tuning kernel untuk eksperimen beban tinggi (1.000 VUs)..."
        sysctl -w net.core.somaxconn=65535
        sysctl -w net.ipv4.tcp_max_syn_backlog=65535
        sysctl -w net.ipv4.ip_local_port_range="1024 65535"
        sysctl -w net.ipv4.tcp_tw_reuse=1
        sysctl -w net.ipv4.tcp_fin_timeout=15
        echo "[✓] Tuning kernel BERHASIL diaktifkan!"
        echo ""
        show_status
        ;;
    off)
        echo "[-] Mengembalikan pengaturan kernel ke default Ubuntu 24.04..."
        sysctl -w net.core.somaxconn=4096
        sysctl -w net.ipv4.tcp_max_syn_backlog=1024
        sysctl -w net.ipv4.ip_local_port_range="32768 60999"
        sysctl -w net.ipv4.tcp_tw_reuse=2
        sysctl -w net.ipv4.tcp_fin_timeout=60
        echo "[✓] Pengaturan kernel BERHASIL dikembalikan ke nilai bawaan (default)!"
        echo ""
        show_status
        ;;
    status|*)
        show_status
        echo ""
        echo "Panduan penggunaan:"
        echo "  sudo $0 on      -> Aktifkan mode eksperimen skripsi"
        echo "  sudo $0 off     -> Matikan & kembalikan ke default Ubuntu"
        echo "  $0 status       -> Tampilkan status konfigurasi saat ini"
        ;;
esac
