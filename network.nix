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
    dns = "default"; # 'default' 'systemd-resolved'
  };
  networking.nameservers = [ ];
  networking.enableIPv6 = true;

  services.resolved.enable = false; # systemd-resolved

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
    address = [ "REDACTED-WG-ADDR/32" ];
    dns = [ "REDACTED-WG-DNS" ];
    privateKeyFile = "/etc/secrets/wireguard/privateKey";
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
    allowedUDPPorts = [
      5353
      7236
      7011
      6001
      6000
    ]; # SpotifyConnect, 7011, 6001, 6000 for uxplay -p
    allowedTCPPorts = [
      57621
      7236
      7250
      7100
      7000
      7001
    ]; # Spotify - local files sync with mobile devices, 7100, 7000, 7001 for uxplay -p

    trustedInterfaces = [ "p2p-wl+" ];
  };

}
