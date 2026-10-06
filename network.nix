# /etc/nixos/network.nix

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  private = import ./private.nix;
  ssidPattern = lib.concatStringsSep "|" (map (s: "\"${s}\"") private.trustedSSIDs);
  # A wired network has no name to go by: it is trusted when the MAC address of its
  # default gateway is listed in private.nix. With none listed, every one is foreign.
  trustedGateways = pkgs.writeText "wg-auto-trusted-gateways" (
    lib.concatMapStrings (mac: "${lib.toLower mac}\n") (private.trustedGatewayMACs or [ ])
  );

  # wg-quick marks the tunnel's own packets with this (FwMark below), which is how the
  # kill switch tells them from everything else on the way out.
  wgMark = 51820;

  # The kill switch: nothing leaves through a Wi-Fi, wired or modem interface but the
  # tunnel's own packets and what it takes to get an address. Its own table, next to
  # the firewall's, so that taking it away is one command. Traffic through wg0, lo and
  # the containers' bridges is not looked at; what containers send out is, as forwarded.
  # `bootstrap` also lets systemd-resolved ask the network's DNS, and nothing else does:
  # the endpoint in private.nix is a name, which wg-quick has to resolve before there is
  # a tunnel to ask through. The names programs look up in that moment are seen by the
  # network; their traffic is not.
  killSwitch =
    bootstrap:
    pkgs.writeText "wg-killswitch-${if bootstrap then "bootstrap" else "strict"}.nft" ''
      table inet wg_killswitch
      delete table inet wg_killswitch
      table inet wg_killswitch {
        chain output {
          type filter hook output priority filter; policy accept;
          oifname "wl*" jump physical
          oifname "en*" jump physical
          oifname "eth*" jump physical
          oifname "usb*" jump physical
          oifname "ww*" jump physical
        }
        chain forward {
          type filter hook forward priority filter; policy accept;
          oifname "wl*" jump physical
          oifname "en*" jump physical
          oifname "eth*" jump physical
          oifname "usb*" jump physical
          oifname "ww*" jump physical
        }
        chain physical {
          meta mark ${toString wgMark} accept
          udp sport 68 udp dport 67 accept
          udp sport 546 udp dport 547 accept
          icmpv6 type { nd-router-solicit, nd-neighbor-solicit, nd-neighbor-advert, mld-listener-report, mld2-listener-report } accept
          ${lib.optionalString bootstrap ''meta skuid "systemd-resolve" meta l4proto { tcp, udp } th dport 53 accept''}
          counter reject with icmpx admin-prohibited
        }
      }
    '';

  # Decides, from the connections that are up, whether the tunnel and the kill switch
  # are on. Run by the NetworkManager dispatcher on every up and down, at boot, and
  # when /var/lib/wg-auto-disabled comes or goes (wg-auto.path).
  #   - the override file is there: no kill switch, the tunnel is left as it is;
  #   - nothing is up (boot, between networks, asleep): the kill switch alone, so that
  #     whatever comes up next starts out closed, with no gap before this runs again;
  #   - every network is trusted: neither;
  #   - any is not: both. The kill switch first, and it stays if the tunnel fails.
  wgAuto = pkgs.writeShellScript "wg-auto" ''
    PATH=${
      lib.makeBinPath (
        with pkgs;
        [
          coreutils
          gawk
          gnugrep
          gnused
          iproute2
          iputils
          networkmanager
          nftables
          systemd
          util-linux
        ]
      )
    }

    # One at a time: the dispatcher, the path unit and boot can all get here at once.
    exec 9> /run/wg-auto.lock
    flock 9

    trusted_ssid() {
      case "$1" in
        ${ssidPattern})
          return 0 ;;
        *)
          return 1 ;;
      esac
    }

    # ARP, not ping: the kill switch does not look at ARP, and may well be on.
    trusted_gateway() {
      gateway=$(ip -4 route show default dev "$1" | awk '/via/ { print $3; exit }')
      [ -n "$gateway" ] || return 1
      mac=$(arping -c 1 -w 2 -I "$1" "$gateway" | sed -n 's/.*\[\(.*\)\].*/\1/p' | head -n 1 | tr A-F a-f)
      [ -n "$mac" ] && grep -Fxq -- "$mac" ${trustedGateways}
    }

    kill_switch() {
      case "$1" in
        off) nft delete table inet wg_killswitch 2> /dev/null || true ;;
        bootstrap) nft -f ${killSwitch true} ;;
        strict) nft -f ${killSwitch false} ;;
      esac || echo "wg-auto: cannot set the kill switch to $1" >&2
    }

    # Respect a manual override: `touch /var/lib/wg-auto-disabled` keeps all of
    # this off (rm to re-enable).
    if [ -e /var/lib/wg-auto-disabled ]; then
      kill_switch off
      exit 0
    fi

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

    if [ "$up" = 0 ]; then
      kill_switch strict
    elif [ "$foreign" = 0 ]; then
      systemctl stop wg-quick-wg0.service 2> /dev/null || true
      kill_switch off
    elif systemctl is-active --quiet wg-quick-wg0.service; then
      kill_switch strict
    else
      kill_switch bootstrap
      if systemctl start wg-quick-wg0.service; then
        kill_switch strict
      else
        echo "wg-auto: wg0 did not come up, the kill switch stays on" >&2
      fi
    fi
  '';
in

{

  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    wifi.backend = "wpa_supplicant";
    wifi.powersave = false;
    wifi.scanRandMacAddress = false;
    dns = "systemd-resolved"; # 'default' 'systemd-resolved'
    dispatcherScripts = [
      {
        # Not for wg0 itself or the containers' interfaces: they change nothing here.
        source = pkgs.writeShellScript "wg-auto-dispatch" ''
          case "$1" in
            wg0 | lo | podman* | veth*) exit 0 ;;
          esac
          case "$2" in
            up | down) exec ${wgAuto} ;;
          esac
        '';
        type = "basic";
      }
    ];
  };
  networking.nameservers = [ ];
  networking.enableIPv6 = true;

  services.resolved.enable = true; # systemd-resolved
  # Nothing here resolves bare hostnames: no samba/cifs client, wsdd is not installed
  # and mDNS already covers the LAN. Off to avoid LLMNR poisoning on untrusted networks.
  services.resolved.settings.Resolve.LLMNR = false;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
      domain = true;
    };
  };

  networking.wg-quick.interfaces.wg0 = {
    autostart = false;
    listenPort = 51820;
    address = [ private.wg.address ];
    dns = [ private.wg.dns ];
    privateKeyFile = "/etc/secrets/wireguard/privateKey";
    # wg-quick would pick this number itself, as long as nothing else has taken it;
    # the kill switch counts on it.
    extraOptions.FwMark = toString wgMark;
    peers = [
      {
        publicKey = private.wg.peerPublicKey;
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        endpoint = private.wg.endpoint;
        persistentKeepalive = 25;
      }
    ];
    # postUp = " ";
  };

  # At boot, before any interface is configured: NetworkManager is not there to ask
  # yet, which wg-auto takes for nothing being up, and the kill switch goes on.
  systemd.services.wg-auto = {
    description = "WireGuard and its kill switch, by the networks that are up";
    wantedBy = [ "network-pre.target" ];
    before = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = wgAuto;
    };
  };
  # The override takes effect when it is set or removed, not at the next change of
  # network: with only the tunnel stopped, the kill switch would leave no network at all.
  systemd.paths.wg-auto = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = "/var/lib/wg-auto-disabled";
  };

  # wg-auto comes back on every boot: the manual override (see wgAuto above) holds
  # for the session, not across a restart.
  systemd.tmpfiles.rules = [ "r! /var/lib/wg-auto-disabled" ];

  networking.firewall = {
    checkReversePath = "loose";
    logReversePathDrops = true;
    allowedUDPPorts = [
      5353
      7236
      # 7011
      # 6001
      # 6000
    ]; # SpotifyConnect, 7011, 6001, 6000 for uxplay -p
    allowedTCPPorts = [
      57621
      7236
      7250
      # 7100
      # 7000
      # 7001
    ]; # Spotify - local files sync with mobile devices, 7100, 7000, 7001 for uxplay -p
  };

}
