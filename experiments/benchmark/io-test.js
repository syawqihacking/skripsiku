import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// ==============================================================================
// SKENARIO UJI BEBAN I/O-BOUND (GRAFANA k6)
// Menguji /api/io dengan delay asinkron 150 ms (menguji antrean soket konkuren)
// Profil beban bertahap (Ramping VUs: 100 -> 500 -> 1.000 VUs)
// ==============================================================================

export const reqBackend1 = new Counter('backend_1_requests');
export const reqBackend2 = new Counter('backend_2_requests');
export const reqBackend3 = new Counter('backend_3_requests');
export const errorRate = new Rate('custom_error_rate');
export const ioLatency = new Trend('io_endpoint_duration', true);

export const options = {
    stages: [
        { duration: '1m', target: 100 },  // Tahap pemanasan (Warm-up) 100 VUs
        { duration: '3m', target: 500 },  // Beban menengah 500 VUs
        { duration: '4m', target: 1000 }, // Beban puncak (Peak saturation) 1.000 VUs
        { duration: '2m', target: 0 },    // Penurunan beban (Cool-down)
    ],
    thresholds: {
        http_req_failed: ['rate<0.02'], // Toleransi error rate maksimal 2%
        http_req_duration: ['p(95)<1000', 'p(99)<2000'], // Latensi I/O ekspektasi p95 < 1s
    },
};

const BASE_URL = __ENV.TARGET_URL || 'http://localhost';

export default function () {
    const res = http.get(`${BASE_URL}/api/io`, {
        timeout: '10s',
        tags: { endpoint: 'io_bound' },
    });

    const isSuccess = check(res, {
        'status is 200': (r) => r.status === 200,
        'has valid result': (r) => r.body && r.body.includes('completed'),
    });

    errorRate.add(!isSuccess);
    ioLatency.add(res.timings.duration);

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

    sleep(0.05);
}
