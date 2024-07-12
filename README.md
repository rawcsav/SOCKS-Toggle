# SOCKS Proxy Toggle for macOS

I got annoyed with having to traverse into Apple's System Preferences to enable or disable the SOCKS proxy every time I wanted to enable/disable it.
So, I decided to automate the process with a simple shell script that toggles the SOCKS proxy on or off with a single click or command. I've compiled it as an app in order to place the icon in my Mac's dock for easy access.
## Features
- Provides notifications on the status of the SOCKS proxy (enabled or disabled).
- Settings for the Wi-Fi service, SOCKS proxy IP, and port.
- Persistent configuration: User-specified options are saved and used for subsequent toggles.
- Has a "Mullvad" mode which disallows the proxy from starting if a Mullvad VPN is not also running.
## Prerequisites

- macOS operating system
- SOCKS proxy server details (IP address and port)

## Installation

### Script

1. Download the `toggle_socks.sh` script from this repository.
2. Open Terminal and navigate to the directory where the script is located.
3. Make the script executable by running the following command:
   ```bash
   chmod +x toggle_socks.sh
   ```

### Automator App

1. Download the latest release `.zip` file from the releases section of this repository.
2. Unzip the downloaded file.
3. Move the `ToggleSOCKS.app` to your Applications folder.

## Usage

### Script

1. Open Terminal and navigate to the directory where the `toggle_socks_proxy.sh` script is located.
2. Run the script with the following command:
   ```bash
   ./toggle_socks.sh [-s <wifi_service>] [-i <proxy_ip>] [-p <proxy_port>] [-m true|false] [-v]
   ```
   - `-s <wifi_service>`: Specify the Wi-Fi service name (default: "Wi-Fi")
   - `-i <proxy_ip>`: Specify the SOCKS proxy IP address (default: "10.64.0.1")
   - `-p <proxy_port>`: Specify the SOCKS proxy port (default: "1080")
   - `-m true|false`: Enable or disable Mullvad VPN connection check
   - `-v`: Enable verbose mode

## Configuration

The default configuration values are:
- Wi-Fi service: `Wi-Fi`
- SOCKS proxy IP: `10.64.0.1`
- SOCKS proxy port: `1080`
- Mullvad VPN connection check: Disabled
- Verbose mode: Disabled

If you need to customize these values, you can modify the script accordingly or provide the options when running the script. When running the script or app with custom options, those options will be saved and used for subsequent toggles.

## Benefits of Using SOCKS Proxies

- Enhances privacy and security by masking your IP address.
- Bypasses network restrictions and access geo-blocked content.
- Improves performance by reducing latency and bandwidth usage.

## Future Plans

- **Translation to Go**: Plans are in place to translate this script into Go for improved performance and cross-platform compatibility.
