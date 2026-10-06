# After a resume (powerManagement.resumeCommands).
set -e

# The RTL8156 may autosuspend again, see sleep-pre.sh.
for dev in /sys/bus/usb/devices/*; do
  [ "$(cat "$dev/idVendor" 2>/dev/null):$(cat "$dev/idProduct" 2>/dev/null)" = 0bda:8156 ] || continue
  echo auto > "$dev/power/control" || true
done

# fprintd loses the reader over a suspend; D-Bus starts a new one.
systemctl stop fprintd.service || true

# WiFi first, and neither failing may keep the other from being tried.
modprobe mt7925e || echo "resume: cannot load mt7925e" >&2
modprobe amdxdna || echo "resume: cannot load amdxdna" >&2
