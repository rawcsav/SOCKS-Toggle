#!/bin/bash
# toggle_socks_proxy.sh
#
# This script toggles the SOCKS proxy on or off for a specified Wi-Fi service on macOS.
# It is designed to work with Mullvad VPN's SOCKS proxy feature for both OpenVPN and WireGuard.
#
# Usage:
# chmod +x toggle_socks_proxy.sh   # Make the script executable
# ./toggle_socks_proxy.sh [-s <wifi_service>] [-i <proxy_ip>] [-p <proxy_port>]
#
# Options:
# -s <wifi_service>   Specify the Wi-Fi service name (default: "Wi-Fi")
# -i <proxy_ip>       Specify the SOCKS proxy IP address (default: "10.64.0.1")
# -p <proxy_port>     Specify the SOCKS proxy port (default: "1080")

# Configuration file path
CONFIG_FILE="$HOME/.toggle_socks_proxy.conf"

# Default configuration
WIFI_SERVICE="Wi-Fi"
PROXY_IP="10.64.0.1"
PROXY_PORT="1080"

# Load configuration from file if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Parse command-line arguments
while getopts ":s:i:p:" opt; do
    case $opt in
        s) WIFI_SERVICE="$OPTARG";;
        i) PROXY_IP="$OPTARG";;
        p) PROXY_PORT="$OPTARG";;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
    esac
done

# Save configuration to file
cat > "$CONFIG_FILE" <<EOF
WIFI_SERVICE="$WIFI_SERVICE"
PROXY_IP="$PROXY_IP"
PROXY_PORT="$PROXY_PORT"
EOF

# Function to display a macOS notification
display_notification() {
    local message=$1
    local title=$2
    osascript -e 'display notification "'"$message"'" with title "'"$title"'"'
}

# Check if the specified Wi-Fi service exists
if ! /usr/sbin/networksetup -listnetworkserviceorder | grep -q "$WIFI_SERVICE"; then
    echo "Error: Wi-Fi service '$WIFI_SERVICE' not found."
    display_notification "Error: Wi-Fi service '$WIFI_SERVICE' not found." "Network Setup Error"
    exit 1
fi

# Get the current SOCKS proxy status
current_socks_proxy_status_line=$(/usr/sbin/networksetup -getsocksfirewallproxy "$WIFI_SERVICE" 2>/dev/null | grep 'Enabled')
current_socks_proxy_status=$(echo $current_socks_proxy_status_line | cut -d ' ' -f 2)

echo "Current SOCKS Proxy Status: $current_socks_proxy_status"

# Toggle the SOCKS proxy based on the current status
if [ "$current_socks_proxy_status" = "Yes" ]; then
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
new_socks_proxy_status_line=$(/usr/sbin/networksetup -getsocksfirewallproxy "$WIFI_SERVICE" 2>/dev/null | grep 'Enabled')
new_socks_proxy_status=$(echo $new_socks_proxy_status_line | cut -d ' ' -f 2)

# Display notification based on the new status
if [ "$current_socks_proxy_status" = "$new_socks_proxy_status" ]; then
    display_notification "Failed to toggle SOCKS Proxy for: $WIFI_SERVICE" "Network Setup Error"
else
    if [ "$new_socks_proxy_status" = "Yes" ]; then
        display_notification "SOCKS Proxy Enabled for: $WIFI_SERVICE\nProxy IP: $PROXY_IP\nProxy Port: $PROXY_PORT" "Network Setup"
    else
        display_notification "SOCKS Proxy Disabled for: $WIFI_SERVICE" "Network Setup"
    fi
fi