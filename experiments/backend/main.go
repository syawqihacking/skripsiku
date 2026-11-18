package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

type Response struct {
	Status        string `json:"status"`
	ContainerID   string `json:"container_id"`
	Endpoint      string `json:"endpoint"`
	ExecutionTime string `json:"execution_time_ms"`
	Timestamp     int64  `json:"timestamp"`
	Result        string `json:"result,omitempty"`
}

var containerID string

func init() {
	var err error
	containerID, err = os.Hostname()
	if err != nil {
		containerID = "unknown-container"
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Backend-Server", containerID)
	json.NewEncoder(w).Encode(Response{
		Status:      "healthy",
		ContainerID: containerID,
		Endpoint:    "/health",
		Timestamp:   time.Now().UnixMilli(),
	})
}

// cpuHandler menjalankan komputasi kriptografis berulang (SHA-256) untuk memicu utilisasi vCPU penuh
func cpuHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	// Default 10.000 iterasi hash SHA-256 berantai
	iterations := 10000
	if iterParam := r.URL.Query().Get("iter"); iterParam != "" {
		if val, err := strconv.Atoi(iterParam); err == nil && val > 0 {
			iterations = val
		}
	}

	data := []byte("uniba-madura-skripsi-benchmarking-seed-" + strconv.FormatInt(start.UnixNano(), 10))
	for i := 0; i < iterations; i++ {
		hash := sha256.Sum256(data)
		data = hash[:]
	}

	elapsed := float64(time.Since(start).Microseconds()) / 1000.0

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Backend-Server", containerID)
	json.NewEncoder(w).Encode(Response{
		Status:        "success",
		ContainerID:   containerID,
		Endpoint:      "/api/cpu",
		ExecutionTime: fmt.Sprintf("%.2f", elapsed),
		Timestamp:     time.Now().UnixMilli(),
		Result:        hex.EncodeToString(data),
	})
}

// ioHandler mensimulasikan latensi operasi basis data atau panggilan API eksternal (150ms non-blocking)
func ioHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	delay := 150 * time.Millisecond
	if delayParam := r.URL.Query().Get("delay"); delayParam != "" {
		if ms, err := strconv.Atoi(delayParam); err == nil && ms >= 0 {
			delay = time.Duration(ms) * time.Millisecond
		}
	}

	time.Sleep(delay)

	elapsed := float64(time.Since(start).Microseconds()) / 1000.0

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Backend-Server", containerID)
	json.NewEncoder(w).Encode(Response{
		Status:        "success",
		ContainerID:   containerID,
		Endpoint:      "/api/io",
		ExecutionTime: fmt.Sprintf("%.2f", elapsed),
		Timestamp:     time.Now().UnixMilli(),
		Result:        fmt.Sprintf("I/O delay of %v completed", delay),
	})
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", healthHandler)
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/api/cpu", cpuHandler)
	mux.HandleFunc("/api/io", ioHandler)

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Printf("[INFO] Backend container %s listening on port %s...", containerID, port)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("[FATAL] Server error: %v", err)
	}
}
