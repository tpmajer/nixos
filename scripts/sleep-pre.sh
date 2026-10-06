# Before a suspend (powerManagement.powerDownCommands). See notes/s2idle.md
# and notes/rtl8156.md.
set -e

# Out of the s2idle path; sleep-post.sh loads them again.
rmmod amdxdna 2>/dev/null || true
rmmod mt7925e 2>/dev/null || true

# The RTL8156 Ethernet card (0bda:8156) must not wake the laptop. Only with a
# link: without one it is left autosuspended. power/control=on keeps r8152
# from setting the wakeup flag again before the suspend.
for dev in /sys/bus/usb/devices/*; do
  [ "$(cat "$dev/idVendor" 2>/dev/null):$(cat "$dev/idProduct" 2>/dev/null)" = 0bda:8156 ] || continue
  for net in "$dev"/*/net/*; do
    [ "$(cat "$net/carrier" 2>/dev/null)" = 1 ] || continue
    echo on > "$dev/power/control" || echo "rtl8156: cannot keep ${dev##*/} from autosuspending" >&2
    driver=$(basename "$(readlink -f "$net/device/driver")")
    if [ "$driver" = r8152 ]; then
      ethtool -s "${net##*/}" wol d || echo "rtl8156: cannot turn WoL off on ${net##*/}" >&2
    else
      echo "rtl8156: ${net##*/} is driven by $driver, not r8152: no WoL to turn off" >&2
    fi
    echo disabled > "$dev/power/wakeup" || true
    wakeup=$(cat "$dev/power/wakeup" 2>/dev/null || true)
    [ "$wakeup" = disabled ] || echo "rtl8156: power/wakeup of ${dev##*/} is '$wakeup': it can wake the laptop" >&2
  done
done
