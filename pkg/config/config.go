package config

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

type Config struct {
	WifiService  string
	ProxyIP      string
	ProxyPort    string
	CheckMullvad bool
}

const configFile = "config.conf"

func LoadConfig() (*Config, error) {
	config := &Config{
		WifiService:  "Wi-Fi",
		ProxyIP:      "10.64.0.1",
		ProxyPort:    "1080",
		CheckMullvad: false,
	}

	file, err := os.Open(configFile)
	if err != nil {
		fmt.Println("No configuration file found. Please enter settings or press enter to use default values.")
		reader := bufio.NewReader(os.Stdin)

		fmt.Print("Enter Wi-Fi Service Name (default: Wi-Fi): ")
		wifiService, _ := reader.ReadString('\n')
		config.WifiService = strings.TrimSpace(wifiService)
		if config.WifiService == "" {
			config.WifiService = "Wi-Fi"
		}

		fmt.Print("Enter Proxy IP (default: 10.64.0.1): ")
		proxyIP, _ := reader.ReadString('\n')
		config.ProxyIP = strings.TrimSpace(proxyIP)
		if config.ProxyIP == "" {
			config.ProxyIP = "10.64.0.1"
		}

		fmt.Print("Enter Proxy Port (default: 1080): ")
		proxyPort, _ := reader.ReadString('\n')
		config.ProxyPort = strings.TrimSpace(proxyPort)
		if config.ProxyPort == "" {
			config.ProxyPort = "1080"
		}

		fmt.Print("Enable Mullvad VPN connection check? (true/false, default: false): ")
		checkMullvad, _ := reader.ReadString('\n')
		config.CheckMullvad = strings.TrimSpace(checkMullvad) == "true"

		SaveConfig(config)
	} else {
		defer file.Close()
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			line := scanner.Text()
			parts := strings.SplitN(line, "=", 2)
			if len(parts) != 2 {
				continue
			}
			key, value := parts[0], parts[1]
			switch key {
			case "WIFI_SERVICE":
				config.WifiService = value
			case "PROXY_IP":
				config.ProxyIP = value
			case "PROXY_PORT":
				config.ProxyPort = value
			case "CHECK_MULLVAD":
				config.CheckMullvad = value == "true"
			}
		}
	}

	return config, nil
}

func SaveConfig(config *Config) {
	file, err := os.Create(configFile)
	if err != nil {
		fmt.Println("Error: Failed to write to configuration file at", configFile)
		os.Exit(1)
	}
	defer file.Close()

	fmt.Fprintf(file, "WIFI_SERVICE=%s\n", config.WifiService)
	fmt.Fprintf(file, "PROXY_IP=%s\n", config.ProxyIP)
	fmt.Fprintf(file, "PROXY_PORT=%s\n", config.ProxyPort)
	fmt.Fprintf(file, "CHECK_MULLVAD=%t\n", config.CheckMullvad)
}
