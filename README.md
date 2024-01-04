# Mullvad VPN SOCKS Proxy Toggle

Toggle the SOCKS proxy for Mullvad VPN on macOS with a script or Automator app.

## Quick Start

- **Script**: `chmod +x toggle_socks_proxy.sh && ./toggle_socks_proxy.sh`
- **Automator App**: Download, unzip, and run `ToggleSOCKS.app`.

## About

This tool toggles the SOCKS proxy for Mullvad VPN's OpenVPN and WireGuard protocols, providing notifications on status changes.

## Installation

- **Script**: Download `toggle_socks_proxy.sh` from this repository.
- **Automator App**: Download the latest `.zip` from the releases, unzip, and move to Applications.

## Usage

- **Script**: Run `./toggle_socks_proxy.sh` in the terminal.
- **Automator App**: Double-click `ToggleSOCKS.app`.

## Configuration

Default settings:
- Wi-Fi service: `Wi-Fi`
- SOCKS proxy IP: `10.64.0.1` (WireGuard) or `10.8.0.1` (OpenVPN)
- SOCKS proxy port: `1080`

Adjust the script for custom configurations.

## Mullvad SOCKS5 Proxy Benefits

- Acts as a kill switch.
- Reduces CAPTCHAs.
- Provides static IP addresses.

Accessible when connected to Mullvad. For setup, visit [Mullvad SOCKS5 proxy guide](https://mullvad.net/en/help/socks5-proxy/).