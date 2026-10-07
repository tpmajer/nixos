# WireGuard on every network that is not trusted, with a kill switch.
# See notes/wg-auto.md.

{
  pkgs,
  lib,
  private,
  user,
  ...
}:

let
  script = import ./script.nix { inherit pkgs; };

  # One per line. A Wi-Fi is trusted by its SSID, a wired network by the MAC
  # address of its default gateway.
  list = name: items: pkgs.writeText name (lib.concatMapStrings (item: "${item}\n") items);
  trustedSSIDs = list "wg-auto-trusted-ssids" private.trustedSSIDs;
  trustedGateways = list "wg-auto-trusted-gateways" (
    map lib.toLower (private.trustedGatewayMACs or [ ])
  );

  # wg-quick marks the tunnel's own packets with this; the kill switch lets them out.
  wgMark = 51820;

  # The kill switch, an nftables table of its own. strict: nothing out but the
  # tunnel and DHCP, nothing in. bootstrap: also DNS for systemd-resolved, to
  # resolve the endpoint. inbound: all out but mDNS, nothing in.
  killSwitch =
    mode:
    let
      physical = chain: ''
        oifname "wl*" jump ${chain}
        oifname "en*" jump ${chain}
        oifname "eth*" jump ${chain}
        oifname "usb*" jump ${chain}
        oifname "ww*" jump ${chain}
      '';
    in
    pkgs.writeText "wg-killswitch-${mode}.nft" ''
      table inet wg_killswitch
      delete table inet wg_killswitch
      table inet wg_killswitch {
        chain output {
          type filter hook output priority filter; policy accept;
          ${physical "leaving"}
        }
        chain forward {
          type filter hook forward priority filter; policy accept;
          ${physical "leaving"}
        }
        chain input {
          type filter hook input priority filter; policy accept;
          iifname "wl*" jump arriving
          iifname "en*" jump arriving
          iifname "eth*" jump arriving
          iifname "usb*" jump arriving
          iifname "ww*" jump arriving
        }
        chain leaving {
          ${
            if mode == "inbound" then
              ''
                udp dport 5353 counter drop
              ''
            else
              ''
                meta mark ${toString wgMark} accept
                udp sport 68 udp dport 67 accept
                udp sport 546 udp dport 547 accept
                icmpv6 type { nd-router-solicit, nd-neighbor-solicit, nd-neighbor-advert, mld-listener-report, mld2-listener-report } accept
                ${lib.optionalString (
                  mode == "bootstrap"
                ) ''meta skuid "systemd-resolve" meta l4proto { tcp, udp } th dport 53 accept''}
                counter reject with icmpx admin-prohibited
              ''
          }
        }
        chain arriving {
          ct state established,related accept
          udp sport 67 udp dport 68 accept
          udp sport 547 udp dport 546 accept
          icmpv6 type { nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, mld-listener-query } accept
          counter drop
        }
      }
    '';

  wgAuto = script "wg-auto" {
    inputs = with pkgs; [
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
    ];
    env = {
      KILL_SWITCH_STRICT = killSwitch "strict";
      KILL_SWITCH_BOOTSTRAP = killSwitch "bootstrap";
      KILL_SWITCH_INBOUND = killSwitch "inbound";
      TRUSTED_SSIDS = trustedSSIDs;
      TRUSTED_GATEWAYS = trustedGateways;
    };
  };
in

{
  networking.wg-quick.interfaces.wg0 = {
    autostart = false;
    address = [ private.wg.address ];
    dns = [ private.wg.dns ];
    privateKeyFile = "/etc/secrets/wireguard/privateKey";
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
  };

  # On every connection going up or down, but for wg0's own and the containers'.
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeShellScript "wg-auto-dispatch" ''
        case "$1" in
          wg0 | lo | podman* | veth*) exit 0 ;;
        esac
        case "$2" in
          up | down) exec ${lib.getExe wgAuto} ;;
        esac
      '';
      type = "basic";
    }
  ];

  # At boot, before NetworkManager: nothing is up, so the kill switch goes on.
  systemd.services.wg-auto = {
    description = "WireGuard and its kill switch, by the networks that are up";
    wantedBy = [ "network-pre.target" ];
    before = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe wgAuto;
    };
  };
  # And when the override is set or removed.
  systemd.paths.wg-auto = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = "/var/lib/wg-auto-disabled";
  };

  # The override lasts until the next boot; removing it needs no password.
  systemd.tmpfiles.rules = [ "r! /var/lib/wg-auto-disabled" ];
  security.sudo.extraConfig = ''
    ${user} ALL=(root) NOPASSWD: /run/current-system/sw/bin/rm -f /var/lib/wg-auto-disabled
  '';
}
