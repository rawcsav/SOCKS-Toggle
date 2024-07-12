package main

import (
	"flag"
	"fmt"
	"os"

	"socksToggle/pkg/config"
	"socksToggle/pkg/network"
	"socksToggle/pkg/notification"
)

var (
	wifiService  string
	proxyIP      string
	proxyPort    string
	checkMullvad bool
	verbose      bool
)

func init() {
	flag.StringVar(&wifiService, "s", "", "Specify the Wi-Fi service name (default: 'Wi-Fi')")
	flag.StringVar(&proxyIP, "i", "", "Specify the SOCKS proxy IP address (default: '10.64.0.1')")
	flag.StringVar(&proxyPort, "p", "", "Specify the SOCKS proxy port (default: '1080')")
	flag.BoolVar(&checkMullvad, "m", false, "Enable or disable Mullvad VPN connection check")
	flag.BoolVar(&verbose, "v", false, "Enable verbose mode")
}

func main() {
	flag.Parse()

	var cfg, err = config.LoadConfig()
	if err != nil {
		fmt.Println("Error loading configuration:", err)
		os.Exit(1)
	}

	if wifiService != "" {
		cfg.WifiService = wifiService
	}
	if proxyIP != "" {
		cfg.ProxyIP = proxyIP
	}
	if proxyPort != "" {
		cfg.ProxyPort = proxyPort
	}
	if checkMullvad {
		cfg.CheckMullvad = checkMullvad
	}

	currentStatus, err := network.GetSocksProxyStatus(cfg.WifiService)
	if err != nil {
		fmt.Println("Error getting SOCKS proxy status:", err)
		os.Exit(1)
	}

	if currentStatus {
		fmt.Println("Disabling SOCKS Proxy...")
		network.DisableSocksProxy(cfg.WifiService)
	} else {
		if cfg.CheckMullvad {
			// Implement Mullvad VPN check here
			// For now, we'll assume it's always connected
			fmt.Println("Mullvad VPN is connected.")
		}
		fmt.Println("Enabling SOCKS Proxy...")
		if !network.EnableSocksProxy(cfg.WifiService, cfg.ProxyIP, cfg.ProxyPort) {
			notification.DisplayNotification("Failed to enable SOCKS Proxy for: "+cfg.WifiService, "Network Setup Error")
			os.Exit(1)
		}
	}

	newStatus, err := network.GetSocksProxyStatus(cfg.WifiService)
	if err != nil {
		fmt.Println("Error getting new SOCKS proxy status:", err)
		os.Exit(1)
	}

	if currentStatus == newStatus {
		notification.DisplayNotification("Failed to toggle SOCKS Proxy for: "+cfg.WifiService, "Network Setup Error")
	} else {
		if newStatus {
			notification.DisplayNotification(fmt.Sprintf("SOCKS Proxy Enabled for: %s\nProxy IP: %s\nProxy Port: %s", cfg.WifiService, cfg.ProxyIP, cfg.ProxyPort), "Network Setup")
		} else {
			notification.DisplayNotification("SOCKS Proxy Disabled for: "+cfg.WifiService, "Network Setup")
		}
	}
}
