package network

import (
	"fmt"
	"os/exec"
	"strings"
	"time"
)

func CheckInternetConnection(proxyIP, proxyPort string) bool {
	testURL := "https://www.google.com"
	timeout := 5 * time.Second

	cmd := exec.Command("curl", "--socks5", fmt.Sprintf("%s:%s", proxyIP, proxyPort), "-s", "--head", "--request", "GET", testURL, "--connect-timeout", fmt.Sprintf("%d", int(timeout.Seconds())))
	output, err := cmd.Output()
	if err != nil {
		fmt.Println("Proxy connection failed.")
		return false
	}

	if strings.Contains(string(output), "HTTP/") {
		fmt.Println("Successfully connected to the internet through the proxy.")
		return true
	}

	fmt.Println("Proxy connection failed.")
	return false
}

func EnableSocksProxy(wifiService, proxyIP, proxyPort string) bool {
	cmd := exec.Command("/usr/sbin/networksetup", "-setsocksfirewallproxy", wifiService, proxyIP, proxyPort)
	if err := cmd.Run(); err != nil {
		fmt.Println("Error: Failed to set SOCKS proxy.")
		return false
	}

	cmd = exec.Command("/usr/sbin/networksetup", "-setsocksfirewallproxystate", wifiService, "on")
	if err := cmd.Run(); err != nil {
		fmt.Println("Error: Failed to enable SOCKS proxy.")
		return false
	}

	if CheckInternetConnection(proxyIP, proxyPort) {
		return true
	} else {
		cmd = exec.Command("/usr/sbin/networksetup", "-setsocksfirewallproxystate", wifiService, "off")
		cmd.Run()
		fmt.Println("Proxy disabled due to connectivity issues.")
		return false
	}
}

func DisableSocksProxy(wifiService string) {
	cmd := exec.Command("/usr/sbin/networksetup", "-setsocksfirewallproxystate", wifiService, "off")
	cmd.Run()
}

func GetSocksProxyStatus(wifiService string) (bool, error) {
	cmd := exec.Command("/usr/sbin/networksetup", "-getsocksfirewallproxy", wifiService)
	output, err := cmd.Output()
	if err != nil {
		return false, err
	}

	return strings.Contains(string(output), "Enabled: Yes"), nil
}
