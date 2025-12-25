# /etc/nixos/network.nix

{
  config,
  pkgs,
  inputs,
  ...
}:

{

  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    wifi.backend = "wpa_supplicant";
    dns = "systemd-resolved";
  };

  networking.enableIPv6 = true;

  networking.wg-quick.interfaces.wg0 = {
    autostart = false;
    listenPort = 51820;
    address = [ "REDACTED-WG-ADDR/32" ];
    dns = [ "REDACTED-WG-DNS" ];
    privateKeyFile = "/etc/wireguard/privateKey";
    peers = [
      {
        publicKey = "REDACTED-WG-PUBKEY";
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        endpoint = "REDACTED-ENDPOINT:51820";
        persistentKeepalive = 25;
      }
    ];
    # postUp = " ";
  };

  networking.firewall = {
    logReversePathDrops = true;
    extraCommands = ''
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
    '';
    allowedUDPPorts = [ 5353 7236 ]; # SpotifyConnect
    allowedTCPPorts = [ 57621 7236 7250 ]; # Spotify - local files sync with mobile devices

	trustedInterfaces = [ "p2p-wl+" ];
  };

  services.resolved.enable = true;

}
