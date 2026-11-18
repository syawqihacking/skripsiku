#!/usr/bin/env python3
"""
Audit Log Parser & MAPE Precision Calculator
Skripsi: Analisis Perbandingan Kinerja NGINX dan HAProxy pada Docker Heterogen
Penulis: Ahmad Muqtafi (2302310264)
"""

import sys
import re
import argparse
from collections import Counter

def parse_nginx_log(log_path):
    """
    Mengekstrak upstream_addr dari format audit_log NGINX:
    upstream_addr="172.28.0.2:8080" atau "web-backend-1:8080"
    """
    counts = Counter()
    pattern = re.compile(r'upstream_addr="([^"]+)"')
    total = 0

    with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            match = pattern.search(line)
            if match:
                addr = match.group(1).split(',')[0].strip() # Ambil node pertama jika ada retry
                counts[addr] += 1
                total += 1
    return counts, total

def parse_haproxy_log(log_path):
    """
    Mengekstrak nama backend server dari format HTTP log HAProxy
    Contoh: ... web_backends/web1 ...
    """
    counts = Counter()
    pattern = re.compile(r'web_backends/(web\d+)')
    total = 0

    with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            match = pattern.search(line)
            if match:
                node = match.group(1)
                counts[node] += 1
                total += 1
    return counts, total

def calculate_mape(actual_counts, is_weighted=True):
    # Mapping node ke urutan container 1, 2, 3
    # Target proporsi ideal
    if is_weighted:
        # Rasio 1:2:4 -> 1/7, 2/7, 4/7
        p_ideal = [100.0 * 1.0 / 7.0, 100.0 * 2.0 / 7.0, 100.0 * 4.0 / 7.0]
    else:
        # Tanpa bobot -> 33.33% merata
        p_ideal = [100.0 / 3.0, 100.0 / 3.0, 100.0 / 3.0]

    total_reqs = sum(actual_counts.values())
    if total_reqs == 0:
        print("[ERROR] Total log permintaan kosong.")
        return

    # Normalisasi identitas container ke index 0, 1, 2
    nodes_sorted = sorted(actual_counts.keys())
    print(f"\n========================================================")
    print(f"HASIL AUDIT PRESISI DISTRIBUSI TRAFIK AKTUAL")
    print(f"========================================================")
    print(f"Total Permintaan Terproses: {total_reqs:,}")
    print(f"Mode Algoritma: {'Berbobot (WRR/WLC - 1:2:4)' if is_weighted else 'Tanpa Bobot (RR/LC - 1:1:1)'}")
    print(f"--------------------------------------------------------")
    print(f"{'Node Backend':<18} | {'Volume':<10} | {'P_Aktual (%)':<14} | {'P_Ideal (%)':<14} | {'Deviasi (%)':<12}")
    print(f"--------------------------------------------------------")

    deviations = []
    for idx, node in enumerate(nodes_sorted):
        vol = actual_counts[node]
        p_act = (vol / total_reqs) * 100.0
        p_id = p_ideal[idx] if idx < len(p_ideal) else (100.0 / len(nodes_sorted))
        dev = abs(p_act - p_id) / p_id * 100.0
        deviations.append(dev)
        print(f"{node:<18} | {vol:<10,d} | {p_act:<14.2f} | {p_id:<14.2f} | {dev:<12.2f}")

    mape = sum(deviations) / len(deviations) if deviations else 0.0
    print(f"--------------------------------------------------------")
    print(f"Mean Absolute Percentage Error (MAPE): {mape:.2f}%")
    print(f"Kategori Presisi: {'SANGAT PRESISI (< 5%)' if mape < 5 else 'CUKUP PRESISI (5 - 10%)' if mape < 10 else 'DEVIASI TINGGI (> 10%)'}")
    print(f"========================================================\n")

def main():
    parser = argparse.ArgumentParser(description="Log Parser untuk Evaluasi Distribusi Beban Heterogen")
    parser.add_argument("--log", required=True, help="Path ke berkas log (access.log)")
    parser.add_argument("--type", choices=["nginx", "haproxy"], default="nginx", help="Jenis load balancer")
    parser.add_argument("--algorithm", choices=["unweighted", "weighted"], default="weighted", help="Tipe algoritma (unweighted/weighted)")
    args = parser.parse_args()

    if args.type == "nginx":
        counts, total = parse_nginx_log(args.log)
    else:
        counts, total = parse_haproxy_log(args.log)

    calculate_mape(counts, is_weighted=(args.algorithm == "weighted"))

if __name__ == "__main__":
    main()
