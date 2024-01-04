#!/bin/bash
# toggle_socks_proxy.sh
#
# This script toggles the SOCKS proxy on or off for a specified Wi-Fi service on macOS.
# It is designed to work with Mullvad VPN's SOCKS proxy feature for both OpenVPN and WireGuard.
#
# Usage:
# chmod +x toggle_socks_proxy.sh   # Make the script executable
# ./toggle_socks_proxy.sh          # Run the script

# Configuration
# Set the Wi-Fi service name and the SOCKS proxy details here.
WIFI_SERVICE="Wi-Fi"
PROXY_IP="10.64.0.1" # Use 10.8.0.1 for OpenVPN, 10.64.0.1 for WireGuard
PROXY_PORT="1080"

# Function to display a macOS notification
display_notification() {
    local message=$1
    local title=$2
    osascript -e "display notification \"$message\" with title \"$title\""
}

# Get the current SOCKS proxy status more robustly
SOCKS_PROXY_STATUS_LINE=$(/usr/sbin/networksetup -getsocksfirewallproxy "$WIFI_SERVICE" | grep 'Enabled')
SOCKS_PROXY_STATUS=$(echo $SOCKS_PROXY_STATUS_LINE | cut -d ' ' -f 2)

echo "Current SOCKS Proxy Status: $SOCKS_PROXY_STATUS"

# Toggle the SOCKS proxy based on the current status
if [ "$SOCKS_PROXY_STATUS" = "Yes" ]; then
    echo "Disabling SOCKS Proxy..."
    /usr/sbin/networksetup -setsocksfirewallproxystate "$WIFI_SERVICE" off
else
    echo "Enabling SOCKS Proxy..."
    /usr/sbin/networksetup -setsocksfirewallproxy "$WIFI_SERVICE" "$PROXY_IP" "$PROXY_PORT" off
    /usr/sbin/networksetup -setsocksfirewallproxystate "$WIFI_SERVICE" on
fi

# Wait for the system to apply the change
sleep 2

# Recheck the SOCKS proxy status to confirm the change
NEW_SOCKS_PROXY_STATUS_LINE=$(/usr/sbin/networksetup -getsocksfirewallproxy "$WIFI_SERVICE" | grep 'Enabled')
NEW_SOCKS_PROXY_STATUS=$(echo $NEW_SOCKS_PROXY_STATUS_LINE | cut -d ' ' -f 2)

# Display notification based on the new status
if [ "$SOCKS_PROXY_STATUS" = "$NEW_SOCKS_PROXY_STATUS" ]; then
    display_notification "Failed to toggle SOCKS Proxy" "Network Setup Error"
else
    if [ "$NEW_SOCKS_PROXY_STATUS" = "Yes" ]; then
        display_notification "SOCKS Proxy Enabled" "Network Setup"
    else
        display_notification "SOCKS Proxy Disabled" "Network Setup"
    fi
fi