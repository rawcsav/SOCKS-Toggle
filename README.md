# SOCKS Proxy Toggle for macOS

Easily toggle the SOCKS proxy on or off for any SOCKS proxy server on macOS with a script or an Automator app. This tool simplifies the process of enabling or disabling the SOCKS proxy, providing a convenient way to configure and use SOCKS proxies on your Mac.

## Features

- Easily toggle the SOCKS proxy on or off with a single click or command.
- Works with any SOCKS proxy server, not limited to Mullvad VPN.
- Provides notifications on the status of the SOCKS proxy (enabled or disabled).
- Customizable settings for the Wi-Fi service, SOCKS proxy IP, and port.
- Persistent configuration: User-specified options are saved and used for subsequent toggles.

## Prerequisites

- macOS operating system
- SOCKS proxy server details (IP address and port)

## Installation

### Script

1. Download the `toggle_socks_proxy.sh` script from this repository.
2. Open Terminal and navigate to the directory where the script is located.
3. Make the script executable by running the following command:

   ```bash
   chmod +x toggle_socks_proxy.sh
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
   ./toggle_socks_proxy.sh [-s <wifi_service>] [-i <proxy_ip>] [-p <proxy_port>]
   ```

   - `-s <wifi_service>`: Specify the Wi-Fi service name (default: "Wi-Fi")
   - `-i <proxy_ip>`: Specify the SOCKS proxy IP address (default: "127.0.0.1")
   - `-p <proxy_port>`: Specify the SOCKS proxy port (default: "1080")

### Automator App

1. Double-click the `ToggleSOCKS.app` in your Applications folder.

## Configuration

The default configuration values are:

- Wi-Fi service: `Wi-Fi`
- SOCKS proxy IP: `10.64.0.1`
- SOCKS proxy port: `1080`

If you need to customize these values, you can modify the script accordingly or provide the options when running the script. When running the script or app with custom options, those options will be saved and used for subsequent toggles.

## Benefits of Using SOCKS Proxies

- Enhances privacy and security by masking your IP address.
- Bypasses network restrictions and access geo-blocked content.
- Improves performance by reducing latency and bandwidth usage.

## Feedback and Contributions

If you encounter any issues, have suggestions, or would like to contribute to this tool, please open an issue or submit a pull request on the GitHub repository.