# NetworkManager, name resolution and the firewall. WireGuard is in wireguard.nix.

_:

{
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    wifi.backend = "wpa_supplicant";
    wifi.powersave = false;
    wifi.scanRandMacAddress = false;
    dns = "systemd-resolved";
  };
  networking.nameservers = [ ];
  networking.enableIPv6 = true;

  services.resolved.enable = true;
  # Off against LLMNR poisoning on untrusted networks; mDNS covers the LAN.
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

  # Open on trusted networks only: elsewhere the kill switch lets nothing in.
  networking.firewall = {
    checkReversePath = "loose";
    logReversePathDrops = true;
    allowedUDPPorts = [
      7236 # Miracast (gnome-network-displays)
      # 7011 6001 6000 for uxplay -p
    ];
    allowedTCPPorts = [
      57621 # Spotify, local files sync with mobile devices
      7236 # Miracast (gnome-network-displays)
      7250 # Miracast (gnome-network-displays)
      # 7100 7000 7001 for uxplay -p
    ];
  };
}
