#!/bin/bash -e

MODULE_ID_FILE="/run/user/$(id --user)/pulse/rasponkyo-module-ids"

# Function to calculate network address
calculate_network() {
    local ip_address=$1
    local cidr_prefix=$2

    # Convert CIDR prefix to subnet mask
    local mask=$(( 0xffffffff << (32 - cidr_prefix) ))
    local m1=$(( (mask >> 24) & 0xff ))
    local m2=$(( (mask >> 16) & 0xff ))
    local m3=$(( (mask >> 8) & 0xff ))
    local m4=$(( mask & 0xff ))

    # Split IP address into octets
    IFS=. read -r i1 i2 i3 i4 <<< "$ip_address"

    # Use bitwise AND to calculate network address
    local n1=$((i1 & m1))
    local n2=$((i2 & m2))
    local n3=$((i3 & m3))
    local n4=$((i4 & m4))
    echo "$n1.$n2.$n3.$n4/$cidr_prefix"
}

# Function to check if an IP address is private
is_private_ip() {
    local ip=$1
    if [[ $ip =~ ^10\. ]] ||
       [[ $ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] ||
       [[ $ip =~ ^192\.168\. ]]; then
        return 0
    fi
    return 1
}

get_acl() {
    # Get IP addresses and subnet masks of all network interfaces
    local ip_info
    ip_info=$(ip -o -f inet addr show scope global | awk '{print $4}')

    # Initialize array with 127.0.0.1 to store network addresses
    local network_addresses=("127.0.0.1")

    local ip_address
    local cidr_prefix
    local network_address
    for ip in $ip_info; do
        ip_address=$(echo "$ip" | cut -d/ -f1)
        cidr_prefix=$(echo "$ip" | cut -d/ -f2)
        if is_private_ip "$ip_address"; then
            network_address=$(calculate_network_address "$ip_address" "$cidr_prefix")
            network_addresses+=("$network_address")
        fi
    done
    # Return all network addresses separated by ;
    echo "${network_addresses[*]}" | tr ' ' ';'
}

module_is_loaded() {
    local search_key="$1"
    local expected_args="$2"
    while IFS=$'\t' read -r module_id name args; do
        if [[ -z "${expected_args}" && "${search_key}" == "${module_id}" ]] ||
           [[ "${name}" == "${search_key}" && "${args}" == "${expected_args}" ]]; then
            echo "$module_id"
            return 0
        fi
    done < <(pactl list modules short)
    return 1
}

load_module() {
    local module="$1"
    local args="$2"

    logger "Loading PulseAudio ${module} with args: ${args}"
    local module_id
    if module_id=$(module_is_loaded "${module}" "${args}"); then
        logger "${module} with args ${args} already loaded"
    else
        module_id=$(pactl load-module "${module}" "${args}")
    fi

    echo "${module_id}" >> "${MODULE_ID_FILE}"
}

load_modules() {
    if ! systemctl --user --quiet is-active pulseaudio.service; then
        logger "PulseAudio not running, exiting"
        exit 1
    fi
    acl=$(get_acl)
    load_module "module-native-protocol-tcp" "auth-ip-acl=${acl}"
    load_module "module-zeroconf-publish"
}

unload_module() {
    module_id=$1
    if module_is_loaded "${module_id}"; then
        pactl unload-module "${module_id}"
    fi
}

unload_modules() {
    logger "Unloading PulseAudio TCP and Zeroconf modules..."
    while read -r module_id; do
        unload_module "${module_id}"
    done < "$MODULE_ID_FILE"
    rm --force "$MODULE_ID_FILE"
}

case "$1" in
    start)
        load_modules
        ;;
    stop)
        unload_modules
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
