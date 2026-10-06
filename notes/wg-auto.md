# wg-auto: WireGuard and a kill switch by the network

`scripts/wg-auto.sh` decides from the connections that are up whether `wg0` and
the kill switch are on (`modules/wireguard.nix`).

| Connections | Tunnel | Kill switch |
|---|---|---|
| every one trusted | off | off |
| any foreign | on | strict |
| nothing up (boot, between networks, asleep) | as it is | strict |
| override set, every one trusted | as it is | off |
| override set, otherwise | as it is | inbound |

## Trusted networks

Listed in `private.nix`. A Wi-Fi is trusted by its SSID (`trustedSSIDs`). A
wired network has no name to go by: it is trusted when the MAC address of its
default gateway is in `trustedGatewayMACs`, read by ARP, which the kill switch
does not look at. With none listed every wired network is foreign. Modems and
Bluetooth tethering always are. To read the gateway's MAC:

    ip neigh show "$(ip -4 route show default | awk '{ print $3; exit }')"

## When it runs

- The NetworkManager dispatcher, on every connection going up or down, but for
  `wg0` itself and the containers' interfaces.
- `wg-auto.service` at boot, before network-pre.target. NetworkManager is not
  there to ask yet, which counts as nothing being up, so the kill switch goes
  on and whatever comes up next starts out closed.
- `wg-auto.path`, when the override file comes or goes.

## The kill switch

An nftables table of its own (`inet wg_killswitch`), next to the firewall's, so
that taking it away is one command. It looks at Wi-Fi, wired and modem
interfaces (`wl*`, `en*`, `eth*`, `usb*`, `ww*`); traffic through `wg0`, `lo`
and the containers' bridges is not looked at, what containers send out is, as
forwarded.

- **strict**: out go only the tunnel's own packets, told by wg-quick's mark
  (pinned as `FwMark`, 51820), DHCP and neighbour discovery. In come only the
  answers to what was sent, so the ports the firewall has open (Steam,
  localsend, Miracast, mDNS) are open to trusted networks only.
- **bootstrap**: also DNS for systemd-resolved. The endpoint in `private.nix`
  is a name, which wg-quick has to resolve before there is a tunnel. The names
  programs look up in that moment are seen by the network, their traffic is
  not. Left this way on purpose (2026-10-06).
- **inbound**: for the override on a foreign network. Everything may leave but
  mDNS, with which Avahi would announce this host; nothing comes in.

The kill switch goes on before the tunnel is started and stays if it fails.

## The override

`/var/lib/wg-auto-disabled`, set by `wgauto off` and `wgauto up` (the fish
function and Quickshell's network popup, `~/.dotfiles`). Removing it needs no
password (a sudoers rule); setting it does. tmpfiles removes it at boot, so it
lasts for the session.

Captive portals need `wgauto off`, as nothing leaves a foreign network without
the tunnel. Way out if all else fails:

    sudo nft delete table inet wg_killswitch
