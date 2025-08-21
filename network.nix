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
    wifi.backend = "iwd";
    dns = "systemd-resolved";
  };
  networking.wireless.iwd = {
    enable = true;
    settings = {
      IPv6.Enabled = false;
      Settings.AutoConnect = true;
      Settings.BandModifier2_4Ghz = "0";
      Settings.BandModifier5Ghz = "1";
      Settings.BandModifier6Ghz = "10";
    };
  };

  networking.wg-quick.interfaces.wg0 = {
    autostart = false;
    listenPort = 51820;
    address = [ "192.168.6.5/32" ];
    dns = [ "192.168.6.1" ];
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
    postUp = "
      	  systemctl stop firewall.service
      	  systemctl start firewall.service
      	";
  };
  networking.firewall = {
    logReversePathDrops = true;
    extraCommands = "
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
    ";
    extraStopCommands = "
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
    ";
  };

  services.resolved.enable = true;

}
