# Decides, from the connections that are up, whether wg0 and the kill switch
# are on. Run by the NetworkManager dispatcher, at boot, and when the override
# file comes or goes. See notes/wg-auto.md.
#   every network trusted       no tunnel, no kill switch
#   nothing up                  the kill switch alone
#   any network foreign         both
#   override, a foreign network the tunnel as it is, nothing let in

override=/var/lib/wg-auto-disabled

# One at a time: two events can get here at once.
exec 9> /run/wg-auto.lock
flock 9

trusted_ssid() {
  [ -n "$1" ] && grep -Fxq -- "$1" "$TRUSTED_SSIDS"
}

# By ARP, not ping: the kill switch does not look at ARP.
trusted_gateway() {
  gateway=$(ip -4 route show default dev "$1" | awk '/via/ { print $3; exit }')
  [ -n "$gateway" ] || return 1
  mac=$(arping -c 1 -w 2 -I "$1" "$gateway" | sed -n 's/.*\[\(.*\)\].*/\1/p' | head -n 1 | tr A-F a-f)
  [ -n "$mac" ] && grep -Fxq -- "$mac" "$TRUSTED_GATEWAYS"
}

kill_switch() {
  case "$1" in
    off) nft delete table inet wg_killswitch 2> /dev/null || true ;;
    *) nft -f "$1" ;;
  esac || echo "wg-auto: cannot set the kill switch to ${1##*-}" >&2
}

up=0
foreign=0
while IFS=: read -r type uuid device; do
  case "$type" in
    802-11-wireless)
      up=1
      ssid=$(nmcli -g 802-11-wireless.ssid connection show "$uuid" 2> /dev/null | tr -d '"')
      trusted_ssid "$ssid" || foreign=1
      ;;
    802-3-ethernet)
      up=1
      trusted_gateway "$device" || foreign=1
      ;;
    gsm | cdma | bluetooth)
      up=1
      foreign=1
      ;;
  esac
done < <(nmcli -t -f TYPE,UUID,DEVICE connection show --active 2> /dev/null)

if [ -e "$override" ]; then
  if [ "$up" = 1 ] && [ "$foreign" = 0 ]; then
    kill_switch off
  else
    kill_switch "$KILL_SWITCH_INBOUND"
  fi
  exit 0
fi

if [ "$up" = 0 ]; then
  kill_switch "$KILL_SWITCH_STRICT"
elif [ "$foreign" = 0 ]; then
  systemctl stop wg-quick-wg0.service 2> /dev/null || true
  kill_switch off
elif systemctl is-active --quiet wg-quick-wg0.service; then
  kill_switch "$KILL_SWITCH_STRICT"
else
  kill_switch "$KILL_SWITCH_BOOTSTRAP"
  if systemctl start wg-quick-wg0.service; then
    kill_switch "$KILL_SWITCH_STRICT"
  else
    echo "wg-auto: wg0 did not come up, the kill switch stays on" >&2
  fi
fi
