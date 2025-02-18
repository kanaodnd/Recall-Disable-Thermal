#!/bin/sh
while [ -z "$(resetprop sys.boot_completed)" ]; do
  sleep 5
done

apply() {
    local value="$1"
    local file="$2"
    
    if [ -f "$file" ]; then
        echo "$value" > "$file"
    else
        echo "File $file does not exist."
    fi
}

#####################################
## Thermal in /**/**/class ((credit;@hirauki))) ##
####################################

# disable thermal services
disable_thermal_services() {
    for rc in $(find /system/etc/init /vendor/etc/init /odm/etc/init -type f); do
        grep -r "^service" "$rc" | awk '/thermal/ {print $2}'
    done | while read -r svc; do
        echo "Stopping $svc"
        start "$svc"
        stop "$svc"
    done
}

# freeze thermal processes
freeze_thermal_processes() {
    for pid in $(pgrep thermal); do
        echo "Freeze $pid"
        kill -SIGSTOP "$pid"
    done
}

# disable thermal properties
disable_thermal_properties() {
    for thermal in $(resetprop | awk -F '[][]' '/thermal/ {print $2}'); do
        if [[ $(resetprop "$thermal") == running ]] || [[ $(resetprop "$thermal") == restarting ]]; then
            stop "${thermal/init.svc.}"
            sleep 10
            resetprop -n "$thermal" stopped
        fi
    done
}

###############################
### Disable Thermal in /sys/class ###
##############################
disable_thermal_zones() {
    for zone in /sys/class/thermal/thermal_zone*; do
        echo "disabled" > "$zone/mode"
    done
}

# Function to disable thermal files
disable_thermal_files() {
    find /sys/devices/virtual/thermal -type f -exec chmod 000 {} + 2>/dev/null
}

# disable thermal on Snapdragon 
disable_thermal_settings() {
    echo "0" > /sys/kernel/msm_thermal/enabled
    echo "N" > /sys/module/msm_thermal/parameters/enabled
    echo "0" > /sys/module/msm_thermal/core_control/enabled
    echo "0" > /sys/module/msm_thermal/vdd_restriction/enabled
    echo "0" > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input
}

#######################################
### Change Properties or add new Properties ###
######################################
reset_thermal_properties() {
    resetprop -n dalvik.vm.dexopt.thermal-cutoff 0
    resetprop -n sys.thermal.enable false
    resetprop -n ro.thermal_warmreset false
    resetprop -n vendor.thermal.bt_completed 0
}

# del old files temp
remove_thermal_dump_files() {
    rm -f /data/vendor/thermal/{config,thermal.dump,last_thermal.dump,thermal_history.dump}
}

# Function to set the maximum current value
set_max_current() {
    ext() {
        if [ -f "$2" ]; then
            chmod 0666 "$2"
            echo "$1" > "$2"
            chmod 0444 "$2"
        fi
    }
    ext 5000000 /sys/class/power_supply/usb/current_max
    ext 5100000 /sys/class/power_supply/usb/hw_current_max
    ext 5100000 /sys/class/power_supply/usb/pd_current_max
    ext 5100000 /sys/class/power_supply/usb/ctm_current_max
    ext 5000000 /sys/class/power_supply/usb/sdp_current_max
    ext 5000000 /sys/class/power_supply/main/current_max
    ext 5100000 /sys/class/power_supply/main/constant_charge_current_max
    ext 5000000 /sys/class/power_supply/battery/current_max
    ext 5100000 /sys/class/power_supply/battery/constant_charge_current_max
    ext 5500000 /sys/class/qcom-battery/restricted_current
    ext 5000000 /sys/class/power_supply/pc_port/current_max
    ext 5500000 /sys/class/power_supply/battery/constant_charge_current_max
}


# change value 
set_gpu_settings() {
    echo "0" > /sys/class/kgsl/kgsl-3d0/bus_split
    echo "0" > /sys/class/kgsl/kgsl-3d0/throttling
    echo "1" > /sys/class/kgsl/kgsl-3d0/force_clk_on
    echo "1" > /sys/class/kgsl/kgsl-3d0/force_rail_on
    echo "1" > /sys/class/kgsl/kgsl-3d0/force_bus_on
    echo "1" > /sys/class/kgsl/kgsl-3d0/force_no_nap
}

#######################################
### Disable Thermal by change read for G3D ###
######################################
disable_thermal_devices() {
    for device in mali BIG LITTLE G3D; do
        for dir in /sys/devices/platform/*."$device"; do
            [ -e "$dir/all_temp" ] && chmod 000 "$dir/all_temp"
            [ -e "$dir/hotplug_in_temp" ] && chmod 000 "$dir/hotplug_in_temp"
            [ -e "$dir/hotplug_out_temp" ] && chmod 000 "$dir/hotplug_out_temp"
        done
    done
}

#########################################
### Disable Thermal by change read for cpufreq ###
########################################
disable_cpu_freq_limits() {
    for limit in /sys/power/cpufreq_min_limit /sys/power/cpufreq_max_limit; do
        [ -e "$limit" ] && chmod 000 "$limit"
    done
}

# Performs all functions
disable_thermal_services
freeze_thermal_processes
disable_thermal_properties
disable_thermal_zones
disable_thermal_files
disable_thermal_settings
reset_thermal_properties
remove_thermal_dump_files
set_max_current
set_gpu_settings
set_sched_lib
disable_thermal_devices
disable_cpu_freq_limits


echo "haik all don have gud experience"
