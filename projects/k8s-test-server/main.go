package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"sync"
)

// 全局状态码，初始为 200，使用互斥锁保证并发安全
var (
	statusCode  = http.StatusOK
	statusMutex sync.RWMutex
)

// PodInfo 包含 Pod 的 IP 和 hostname
type PodInfo struct {
	IP       string `json:"ip"`
	Hostname string `json:"hostname"`
}

// 获取 Pod 的 IP 地址
// 优先从环境变量 POD_IP 读取，否则获取本机非环回 IP
func getPodIP() string {
	if ip := os.Getenv("POD_IP"); ip != "" {
		return ip
	}

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		log.Printf("获取本机地址失败: %v", err)
		return "unknown"
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() && ipnet.IP.To4() != nil {
			return ipnet.IP.String()
		}
	}
	return "unknown"
}

// 获取当前状态码（线程安全）
func getStatusCode() int {
	statusMutex.RLock()
	defer statusMutex.RUnlock()
	return statusCode
}

// 设置状态码（线程安全）
func setStatusCode(code int) {
	statusMutex.Lock()
	defer statusMutex.Unlock()
	statusCode = code
	log.Printf("状态码已设置为 %d", code)
}

// 主处理函数：返回 Pod 信息，状态码由开关决定
func rootHandler(w http.ResponseWriter, r *http.Request) {
	code := getStatusCode()
	if code != http.StatusOK {
		// 非 200 状态码，只返回状态行，不返回 body
		w.WriteHeader(code)
		return
	}

	// 正常返回 JSON
	hostname, _ := os.Hostname()
	info := PodInfo{
		IP:       getPodIP(),
		Hostname: hostname,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(info)
}

// 开关控制端点：通过查询参数 ?code=502 或 ?code=200 修改状态码
func switchHandler(w http.ResponseWriter, r *http.Request) {
	codeStr := r.URL.Query().Get("code")
	if codeStr == "" {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "缺少 code 参数，示例: /switch?code=502\n")
		return
	}

	var newCode int
	switch codeStr {
	case "200":
		newCode = http.StatusOK
	case "502":
		newCode = http.StatusBadGateway
	default:
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "不支持的 code 参数: %s，仅支持 200 或 502\n", codeStr)
		return
	}

	setStatusCode(newCode)
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "状态码已设置为 %d\n", newCode)
}

// 查看当前状态码
func statusHandler(w http.ResponseWriter, r *http.Request) {
	code := getStatusCode()
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "当前状态码: %d\n", code)
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", rootHandler)         // 主 API，返回 Pod IP 和 hostname
	http.HandleFunc("/switch", switchHandler) // 切换状态码
	http.HandleFunc("/status", statusHandler) // 查看当前状态码

	log.Printf("服务启动，监听端口 %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
