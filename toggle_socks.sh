#!/bin/bash
# Usage:
# chmod +x toggle_socks.sh   # Make the script executable
# ./toggle_socks.sh [-s <wifi_service>] [-i <proxy_ip>] [-p <proxy_port>] [-m true|false] [-v]
#
# Options:
# -s <wifi_service>   Specify the Wi-Fi service name (default: "Wi-Fi")
# -i <proxy_ip>       Specify the SOCKS proxy IP address (default: "10.64.0.1")
# -p <proxy_port>     Specify the SOCKS proxy port (default: "1080")
# -m true|false       Enable or disable Mullvad VPN connection check
# -v                  Enable verbose mode


verbose() {
    [[ ${VERBOSE} -eq 1 ]] && echo "$@"
}

display_notification() {
    osascript -e 'display notification "'"$1"'" with title "'"$2"'"'
}

check_mullvad_connection() {
    local api_response=$(curl -s https://am.i.mullvad.net/connected)
    if [[ "$api_response" == "You are connected to Mullvad"* ]]; then
        verbose "Mullvad VPN is connected."
        return 0
    else
        return 1
    fi
}

check_internet_connection() {
    local test_url="https://www.google.com"
    local timeout=5
    local start_time=$(date +%s)
    if curl --socks5 "$PROXY_IP:$PROXY_PORT" -s --head --request GET "$test_url" --connect-timeout "$timeout" | grep -q "HTTP/[1-3]"; then
        local end_time=$(date +%s)
        local latency=$((end_time - start_time))
        verbose "Latency: ${latency}s"
        return 0
    else
        verbose "Proxy connection failed."
        return 1
    fi
}

enable_socks_proxy() {
    if ! /usr/sbin/networksetup -setsocksfirewallproxy "$WIFI_SERVICE" "$PROXY_IP" "$PROXY_PORT" &&
       ! /usr/sbin/networksetup -setsocksfirewallproxystate "$WIFI_SERVICE" on; then
        echo "Error: Failed to set or enable SOCKS proxy."
        return 1
    fi

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

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        echo "No configuration file found. Please enter settings or press enter to use default values."
        read -p "Enter Wi-Fi Service Name (default: Wi-Fi): " input_wifi_service
        WIFI_SERVICE="${input_wifi_service:-Wi-Fi}"

        read -p "Enter Proxy IP (default: 10.64.0.1): " input_proxy_ip
        PROXY_IP="${input_proxy_ip:-10.64.0.1}"

        read -p "Enter Proxy Port (default: 1080): " input_proxy_port
        PROXY_PORT="${input_proxy_port:-1080}"

        read -p "Enable Mullvad VPN connection check? (true/false, default: false): " input_check_mullvad
        CHECK_MULLVAD="${input_check_mullvad:-false}"

        save_config
    fi
}

CONFIG_FILE="$(dirname "$0")/config.conf"


save_config() {
    echo "Saving configuration to $CONFIG_FILE"
    if ! cat > "$CONFIG_FILE" <<EOF
WIFI_SERVICE="$WIFI_SERVICE"
PROXY_IP="$PROXY_IP"
PROXY_PORT="$PROXY_PORT"
CHECK_MULLVAD=$CHECK_MULLVAD
EOF
    then
        echo "Error: Failed to write to configuration file at $CONFIG_FILE"
        exit 1
    else
        echo "Configuration saved successfully."
    fi
}

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

load_config

if ! /usr/sbin/networksetup -listnetworkserviceorder | grep -q "^([0-9]\+) $WIFI_SERVICE$"; then
    echo "Error: Wi-Fi service '$WIFI_SERVICE' not found."
    display_notification "Error: Wi-Fi service '$WIFI_SERVICE' not found." "Network Setup Error"
    exit 1
fi

current_socks_proxy_status=$(/usr/sbin/networksetup -getsocksfirewallproxy "$WIFI_SERVICE" | awk '/^Enabled:/ {print $2}')

verbose "Current SOCKS Proxy Status: $current_socks_proxy_status"

if [[ "$current_socks_proxy_status" = "Yes" ]]; then
    echo "Disabling SOCKS Proxy..."
    /usr/sbin/networksetup -setsocksfirewallproxystate "$WIFI_SERVICE" off
else
    if [[ "$CHECK_MULLVAD" = true ]]; then
        check_mullvad_connection
        mullvad_check_result=$?
        if [[ $mullvad_check_result -eq 0 ]]; then
            echo "Enabling SOCKS Proxy..."
            enable_socks_proxy
        else
            echo "Mullvad VPN is not connected. SOCKS Proxy will not be enabled."
            /usr/sbin/networksetup -setsocksfirewallproxystate "$WIFI_SERVICE" off
        fi
    else
        echo "Enabling SOCKS Proxy..."
        enable_socks_proxy
    fi
fi

sleep 2

new_socks_proxy_status=$(/usr/sbin/networksetup -getsocksfirewallproxy "$WIFI_SERVICE" | awk '/^Enabled:/ {print $2}')

if [[ "$current_socks_proxy_status" = "$new_socks_proxy_status" ]]; then
    display_notification "Failed to toggle SOCKS Proxy for: $WIFI_SERVICE" "Network Setup Error"
else
    if [[ "$new_socks_proxy_status" = "Yes" ]]; then
        display_notification "SOCKS Proxy Enabled for: $WIFI_SERVICE\nProxy IP: $PROXY_IP\nProxy Port: $PROXY_PORT" "Network Setup"
    else
        display_notification "SOCKS Proxy Disabled for: $WIFI_SERVICE" "Network Setup"
    fi
fi