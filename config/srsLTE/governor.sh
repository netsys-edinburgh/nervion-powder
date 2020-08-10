#!/bin/bash


cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor


echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor


cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
