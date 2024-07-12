#!/bin/bash
# toggle_socks_proxy.sh
#
# This script toggles the SOCKS proxy on or off for a specified Wi-Fi service on macOS.
# It is designed to work with Mullvad VPN's SOCKS proxy feature for both OpenVPN and WireGuard.
#
# Usage:
# chmod +x toggle_socks_proxy.sh   # Make the script executable
# ./toggle_socks_proxy.sh [-s <wifi_service>] [-i <proxy_ip>] [-p <proxy_port>] [-m true|false] [-v]
#
# Options:
# -s <wifi_service>   Specify the Wi-Fi service name (default: "Wi-Fi")
# -i <proxy_ip>       Specify the SOCKS proxy IP address (default: "10.64.0.1")
# -p <proxy_port>     Specify the SOCKS proxy port (default: "1080")
# -m true|false       Enable or disable Mullvad VPN connection check
# -v                  Enable verbose mode

set -e  # Exit immediately if a command exits with a non-zero status.

# Configuration file path
CONFIG_FILE="$HOME/.toggle_socks_proxy.conf"

# Default configuration
WIFI_SERVICE="Wi-Fi"
PROXY_IP="10.64.0.1"
PROXY_PORT="1080"
CHECK_MULLVAD=false
VERBOSE=0

# Function for verbose output
verbose() {
    if [ "${VERBOSE:-0}" -eq 1 ]; then
        echo "$@"
    fi
}

# Function to display a macOS notification
display_notification() {
    local message=$1
    local title=$2
    osascript -e 'display notification "'"$message"'" with title "'"$title"'"'
}

# Function to check Mullvad VPN connection
check_mullvad_connection() {
    if ! command -v mullvad >/dev/null 2>&1; then
        echo "Mullvad CLI not found. Please install it to use this feature."
        return 3  # Mullvad CLI not installed
    fi

    mullvad_status=$(mullvad status 2>&1)
    if [ $? -ne 0 ]; then
        echo "Error checking Mullvad VPN status: $mullvad_status"
        return 2  # Error checking status
    fi

    if echo "$mullvad_status" | grep -q "Connected"; then
        verbose "Mullvad VPN is connected."
        return 0  # Connected
    else
        verbose "Mullvad VPN is not connected."
        return 1  # Not connected
    fi
}

# Function to check internet connectivity through the proxy and measure latency
check_internet_connection() {
    local test_url="https://www.google.com"
    local timeout=5
    local start_time end_time latency

    start_time=$(date +%s)  # Capture time in seconds
    if curl --socks5 "$PROXY_IP:$PROXY_PORT" -s --head --request GET "$test_url" --connect-timeout "$timeout" | grep "HTTP/[1-3]" > /dev/null; then
        end_time=$(date +%s)  # Capture time in seconds
        latency=$((end_time - start_time))  # Calculate latency in seconds
        verbose "Proxy connection is working. Latency: ${latency}s"  # Output latency in seconds
        return 0
    else
        verbose "Proxy connection failed."
        return 1
    fi
}
# Function to enable SOCKS proxy
enable_socks_proxy() {
    verbose "Enabling SOCKS Proxy..."
    if ! /usr/sbin/networksetup -setsocksfirewallproxy "$WIFI_SERVICE" "$PROXY_IP" "$PROXY_PORT"; then
        echo "Error: Failed to set SOCKS proxy settings."
        return 1
    fi
    if ! /usr/sbin/networksetup -setsocksfirewallproxystate "$WIFI_SERVICE" on; then
        echo "Error: Failed to enable SOCKS proxy."
        return 1
    fi

    # Check internet connectivity through the proxy
    verbose "Checking internet connectivity through the proxy..."
    if check_internet_connection; then
        verbose "Successfully connected to the internet through the proxy."
        return 0
    else
        verbose "Warning: Unable to connect to the internet through the proxy. Disabling proxy."
        /usr/sbin/networksetup -setsocksfirewallproxystate "$WIFI_SERVICE" off
        echo "Proxy disabled due to connectivity issues."
        return 1
    fi
}

# Load configuration from file if it exists
if [ -f "$CONFIG_FILE" ]; then
    verbose "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
else
    verbose "Configuration file not found. Using default settings."
fi

# Parse command-line arguments
while getopts ":s:i:p:m:v" opt; do
    case $opt in
        s) WIFI_SERVICE="$OPTARG";;
        i) PROXY_IP="$OPTARG";;
        p) PROXY_PORT="$OPTARG";;
        m) CHECK_MULLVAD="$OPTARG";;
        v) VERBOSE=1;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
    esac
done

# Save configuration to file
# Note: This will persist any changes made via command-line arguments
verbose "Saving configuration to $CONFIG_FILE"
cat > "$CONFIG_FILE" <<EOF
WIFI_SERVICE="$WIFI_SERVICE"
PROXY_IP="$PROXY_IP"
PROXY_PORT="$PROXY_PORT"
CHECK_MULLVAD=$CHECK_MULLVAD
EOF

verbose "Mullvad VPN check is $(if [ "$CHECK_MULLVAD" = true ]; then echo "enabled"; else echo "disabled"; fi)"

# Check if the specified Wi-Fi service exists
if ! /usr/sbin/networksetup -listnetworkserviceorder | grep -q "^([0-9]\+) $WIFI_SERVICE$"; then
    echo "Error: Wi-Fi service '$WIFI_SERVICE' not found."
    display_notification "Error: Wi-Fi service '$WIFI_SERVICE' not found." "Network Setup Error"
    exit 1
fi

# Get the current SOCKS proxy status
current_socks_proxy_status=$(/usr/sbin/networksetup -getsocksfirewallproxy "$WIFI_SERVICE" | awk '/^Enabled:/ {print $2}')

verbose "Current SOCKS Proxy Status: $current_socks_proxy_status"

# Toggle the SOCKS proxy based on the current status
if [ "$current_socks_proxy_status" = "Yes" ]; then
    echo "Disabling SOCKS Proxy..."
    if ! /usr/sbin/networksetup -setsocksfirewallproxystate "$WIFI_SERVICE" off; then
        echo "Error: Failed to disable SOCKS proxy."
        exit 1
    fi
else
    if [ "$CHECK_MULLVAD" = true ]; then
        check_mullvad_connection
        mullvad_check_result=$?
        case $mullvad_check_result in
            0)  enable_socks_proxy;;
            1)  echo "Warning: Mullvad VPN is not connected. Proceeding with enabling SOCKS proxy."
                enable_socks_proxy
                ;;
            2|3)  echo "Warning: Unable to verify Mullvad VPN connection. Proceeding with enabling SOCKS proxy."
                enable_socks_proxy
                ;;
        esac
    else
        enable_socks_proxy
    fi
fi

# Wait for the system to apply the change
sleep 2

# Recheck the SOCKS proxy status to confirm the change
new_socks_proxy_status=$(/usr/sbin/networksetup -getsocksfirewallproxy "$WIFI_SERVICE" | awk '/^Enabled:/ {print $2}')

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
