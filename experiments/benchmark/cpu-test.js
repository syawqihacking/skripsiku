import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// ==============================================================================
// SKENARIO UJI BEBAN CPU-BOUND (GRAFANA k6)
// Menguji /api/cpu dengan kalkulasi hash SHA-256 intensif
// Profil beban bertahap (Ramping VUs: 100 -> 500 -> 1.000 VUs)
// ==============================================================================

// Metrik Kustom Distribusi Kontainer Backend
export const reqBackend1 = new Counter('backend_1_requests');
export const reqBackend2 = new Counter('backend_2_requests');
export const reqBackend3 = new Counter('backend_3_requests');
export const errorRate = new Rate('custom_error_rate');
export const cpuLatency = new Trend('cpu_endpoint_duration', true);

export const options = {
    stages: [
        { duration: '1m', target: 100 },  // Tahap pemanasan (Warm-up) 100 VUs
        { duration: '3m', target: 500 },  // Beban menengah 500 VUs
        { duration: '4m', target: 1000 }, // Beban puncak (Peak saturation) 1.000 VUs
        { duration: '2m', target: 0 },    // Penurunan beban (Cool-down)
    ],
    thresholds: {
        http_req_failed: ['rate<0.05'], // Toleransi error rate maksimal 5%
        http_req_duration: ['p(95)<3000', 'p(99)<5000'], // Batas SLO p95 < 3s, p99 < 5s saat jenuh
    },
};

const BASE_URL = __ENV.TARGET_URL || 'http://localhost';

export default function () {
    const res = http.get(`${BASE_URL}/api/cpu`, {
        timeout: '10s',
        tags: { endpoint: 'cpu_bound' },
    });

    const isSuccess = check(res, {
        'status is 200': (r) => r.status === 200,
        'has valid result': (r) => r.body && r.body.includes('success'),
    });

    errorRate.add(!isSuccess);
    cpuLatency.add(res.timings.duration);

    // Identifikasi kontainer pemroses dari header respons
    const backendServer = res.headers['X-Backend-Server'];
    if (backendServer) {
        if (backendServer.includes('web-backend-1')) {
            reqBackend1.add(1);
        } else if (backendServer.includes('web-backend-2')) {
            reqBackend2.add(1);
        } else if (backendServer.includes('web-backend-3')) {
            reqBackend3.add(1);
        }
    }

    // Pacing interval adaptif antara 50ms - 200ms
    sleep(0.1);
}
