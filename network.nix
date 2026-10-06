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

  # Decides, from the connections that are up, whether the tunnel is on. Run by the
  # NetworkManager dispatcher on every up and down.
  #   - the override file is there, or nothing is up: the tunnel is left as it is;
  #   - every network is trusted: off;
  #   - any is not: on.
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
          systemd
          util-linux
        ]
      )
    }

    # One at a time: two events can get here at once.
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

    # By the MAC address its default gateway answers ARP with.
    trusted_gateway() {
      gateway=$(ip -4 route show default dev "$1" | awk '/via/ { print $3; exit }')
      [ -n "$gateway" ] || return 1
      mac=$(arping -c 1 -w 2 -I "$1" "$gateway" | sed -n 's/.*\[\(.*\)\].*/\1/p' | head -n 1 | tr A-F a-f)
      [ -n "$mac" ] && grep -Fxq -- "$mac" ${trustedGateways}
    }

    # Respect a manual override: `touch /var/lib/wg-auto-disabled` keeps all of
    # this off (rm to re-enable).
    if [ -e /var/lib/wg-auto-disabled ]; then
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
      exit 0
    elif [ "$foreign" = 0 ]; then
      systemctl stop wg-quick-wg0.service 2> /dev/null || true
    else
      systemctl start wg-quick-wg0.service
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
