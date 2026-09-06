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
        source = pkgs.writeShellScript "wg-auto" ''
          ACTION=$2

          trusted_ssid() {
            case "$1" in
              ${ssidPattern})
                return 0 ;;
              *)
                return 1 ;;
            esac
          }

          if [ "$ACTION" = "up" ]; then
            # Respect a manual override: `touch /var/lib/wg-auto-disabled`
            # keeps wg off despite dispatcher up-events (rm to re-enable).
            if [ -e /var/lib/wg-auto-disabled ]; then
              exit 0
            fi
            SSID=$(${pkgs.networkmanager}/bin/nmcli -g 802-11-wireless.ssid connection show "$CONNECTION_UUID" 2>/dev/null | tr -d '"')
            [ -z "$SSID" ] && exit 0
            if trusted_ssid "$SSID"; then
              systemctl stop wg-quick-wg0.service 2>/dev/null || true
            else
              systemctl start wg-quick-wg0.service
            fi
          fi
        '';
        type = "basic";
      }
    ];
  };
  networking.nameservers = [ ];
  networking.enableIPv6 = true;

  services.resolved.enable = true; # systemd-resolved

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

    trustedInterfaces = [ "p2p-wl+" ];
  };

}
