# /etc/nixos/system.nix

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ./user-services.nix
    # ./llm.nix
    ./printers.nix
    # ./dlna.nix
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
      rocmPackages.rocminfo
    ];
  };
  hardware.steam-hardware.enable = true;
  # xone driver for Xbox controllers over USB and the official Xbox Wireless
  # Adapter (dongle); full GIP protocol, e.g. Elite 2 paddles over cable.
  hardware.xone.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Show battery charge of Bluetooth devices
      };
    };
  };
  hardware.sane.enable = true; # enables support for SANE scanners

  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="PL"
  '';

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 30;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # Belt and braces against the amdgpu MES ring buffer wedge on gfx1150 (gitlab drm/amd#4749).
      # The actual fix (e9f58ff991dd "drm/amdgpu: rework how we handle TLB fences") landed in
      # 6.18.32 and is long since in mainline, so 7.1.x has it too and the param is likely
      # redundant for that bug. Kept because broken CWSR is reported to saturate the MES ring on
      # its own, and it costs nothing here (no compute wave save/restore workloads on this
      # machine).
      "amdgpu.cwsr_enable=0"
      # Diagnostic net for the hang that is still open. Lets amdgpu attempt a GPU reset instead
      # of wedging outright, so a display-engine failure has a chance to end as a recovered hang
      # with something in the journal rather than the silent death that leaves nothing to debug.
      # On 2026-08-06 19:16 the machine died in the s2idle path anyway (black screen on wake,
      # hard reset; journal ends at "PM: suspend entry", pstore empty, no amdgpu reset logged),
      # which is itself a data point: the failure sits below the level where amdgpu can react.
      # Do not remove until that is explained — see debug-session-2026-08-06.2.md.
      "amdgpu.gpu_recovery=1"
    ];
    initrd.luks.devices = {
      # dm-crypt drops discards unless told otherwise, which silently reduces fstrim to a no-op on
      # everything under LUKS — /boot, the one filesystem outside the crypt layer, is then the only
      # thing that ever gets trimmed. Without TRIM the controller goes on preserving and relocating
      # blocks the filesystem freed long ago, paying for it in write throughput and erase cycles.
      # The cost of allowing discards: freed extents read back as zeros rather than ciphertext
      # noise, so the map of free space is no longer secret. Contents, names and keys stay
      # unreadable.
      "luks-175275f3-e11c-4a06-b71a-7050baff3149".allowDiscards = true; # /
      "luks-2388d8ad-9a00-401a-b4b4-8e3582a4ef9f" = {
        device = "/dev/disk/by-uuid/2388d8ad-9a00-401a-b4b4-8e3582a4ef9f";
        allowDiscards = true; # swap
      };
    };
    initrd.availableKernelModules = [ "usbhid" ];
    blacklistedKernelModules = [
      # ucsi_acpi is broken on this Strix Point HW: once loaded it spams
      # "ucsi_acpi USBC000:00: unknown error 256". Re-enable test (2026-06-28) did
      # NOT fix the dead USB-C port (charging is EC-driven, independent of UCSI) and
      # only reintroduced the error 256 spam, confirming the original blacklist reason.
      # The dead port itself turned out to be an EC wedge and cleared on a reboot, so it
      # was never a UCSI problem — no reason to revisit this blacklist over it.
      "ucsi_acpi"
      # Not blacklisted for good: mt7925-init below modprobes it after an FLR on the PCI function.
      # The blacklist only keeps udev from probing it too early. Dropped in 14b4b43 (2026-08-07)
      # on the theory that this failure belonged to the 6.18 pin — "not a single hit on any 7.1.x
      # boot". Disproved on 2026-08-09: a boot died 20s in, inside the mt7925e probe window, the
      # next boot reported a data fabric sync flood as its reset reason, and the two after it hit
      # 'driver own failed' / -5 on 7.1.6 — the first such hits on 7.1.x. Only mt7925e: the NPU at
      # c2:00.1 exposes no reset attribute at all, so its half of the old service never ran.
      "mt7925e"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  console.keyMap = "pl2";

  security.rtkit.enable = true;
  security.polkit.enable = true;
  security.pam.services.hyprlock = {
    fprintAuth = false;
  };
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = lib.mkForce false;
  security.sudo.extraConfig = ''
    Defaults pwfeedback # password input feedback - makes typed password visible as asterisks
    Defaults insults
  '';

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  services = {
    dbus.implementation = "broker";
    hypridle.enable = true;
    gnome.gnome-keyring.enable = true;
    gnome.core-apps.enable = false;
    gnome.tinysparql.enable = true;
    gnome.localsearch.enable = true;
    gvfs.enable = true;
    geoclue2.enable = true;
    power-profiles-daemon.enable = false;
    tlp = {
      enable = true;
      pd.enable = true;
    };
    fwupd.enable = true;
    xserver.xkb = {
      layout = "pl";
      variant = "";
    };
    blueman.enable = true;
    desktopManager.gnome.enable = false;
    displayManager = {
      gdm.enable = true;
      autoLogin = {
        enable = false;
        user = "tpmajer";
      };
    };

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    libinput.enable = true;
    # openlogi ships uaccess rules for Logitech HID++ hidraw/event nodes in
    # lib/udev/rules.d — environment.systemPackages does not install those, so
    # without this the mouse's hidraw node stays root:root 0600 and every
    # openlogi HID++ open fails with EACCES ("No Logitech HID++ devices found").
    udev.packages = [ pkgs.openlogi ];
    flatpak.enable = true;
    envfs.enable = false; # Fuse filesystem that returns symlinks to executables based on the PATH of the requesting process.
    fprintd.enable = true; # 'sudo fprintd-enroll $USER' to enroll
  };

  # GDM 50: gnome-shell of the greeter (libgvc) segfaults in
  # _pa_context_get_card_info_by_index_cb when the greeter's own pipewire-pulse exposes an
  # HDA card whose profile enumeration is not finished yet ("card 52 port N profiles
  # inconsistent (0 < 3)"). The greeter has no use for audio, so don't start pipewire for it.
  systemd.user =
    let
      skipGreeter = {
        unitConfig.ConditionUser = map (u: "!${u}") [
          "gdm-greeter"
          "gdm-greeter-2"
          "gdm-greeter-3"
          "gdm-greeter-4"
          "gdm-greeter-5"
        ];
      };
    in
    {
      services = lib.genAttrs [ "pipewire" "pipewire-pulse" "wireplumber" ] (_: skipGreeter);
      sockets = lib.genAttrs [ "pipewire" "pipewire-pulse" ] (_: skipGreeter);
    };

  # The MT7925E gets a function level reset before the driver attempts 'driver own'. Without it the
  # handshake against a co-processor left in an undefined state stalls on the PCIe bus and trips a
  # hardware-level data fabric sync flood, below the level any software can intercept (which is why
  # pci=noaer never helped). Every probe afterwards then fails with -5 until the machine is fully
  # power-cycled — a warm reboot does not clear it. See debug-session-2026-08-09.md.
  # Order: systemd-udevd → FLR + modprobe → network-pre.target.
  # Note this does not prevent the first sync flood, only the loop that follows it: the FLR runs at
  # boot, and the 2026-08-09 event happened on a cold boot after a clean poweroff. 14b4b43 likewise
  # recorded short sync floods on 7.0.8..7.0.11 with the FLR active, so it reduces rather than
  # eliminates them. The first event is still unexplained.
  systemd.services.mt7925-init = {
    description = "PCIe FLR reset for MT7925 WiFi before driver probe";
    wantedBy = [ "network-pre.target" ];
    before = [ "network-pre.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mt7925-init" ''
        echo 1 > /sys/bus/pci/devices/0000:c0:00.0/reset
        sleep 0.5
        ${pkgs.kmod}/bin/modprobe mt7925e
      '';
    };
  };

  users.users.tpmajer = {
    isNormalUser = true;
    description = "Tomasz Majer";
    extraGroups = [
      "users"
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "scanner"
      "lp"
    ];
    packages = with pkgs; [
    ];
  };

  nixpkgs = {

    config.allowUnfree = true;

    overlays = [
      inputs.mako-blur.overlays.default
      inputs.claude-code.overlays.default
      inputs.niri.overlays.niri
      (self: super: {
        mpv-unwrapped = super.mpv-unwrapped.override {
          ffmpeg = super.ffmpeg-full;
        };
      })
    ];

  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://niri-epireyn.cachix.org"
        "https://claude-code.cachix.org"
      ];
      trusted-public-keys = [
        "niri-epireyn.cachix.org-1:tlVyFN7CtsDT+ZcLPS+ekFWeT1X6X4OqvWqbBMyIzFA="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      ];
    };
    gc = {
      automatic = false;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      gnome-keyring
    ];
  };
  xdg.terminal-exec.enable = true; # Makes nautilus open ghostty insted of kgx

  environment.variables = {
    EDITOR = "micro";
    VISUAL = "micro";
    TERMINAL = "ghostty";
    RUSTICL_ENABLE = "radeonsi";
    AMD_VULKAN_ICD = "RADV";
    XDG_RUNTIME_DIR = "/run/user/$UID"; # set the runtime directory
    NEWT_COLORS = "root=#cdd6f4,#11111b border=#a6e3a1,#11111b window=#11111b,#11111b shadow=#11111b,#11111b title=#a6e3a1,#11111b button=#11111b,#a6e3a1 button_active=#11111b,#1e1e2e actbutton=#a6e3a1,#11111b compactbutton=#a6e3a1,#11111b checkbox=#a6e3a1,#11111b entry=#a6e3a1,#11111b disentry=#11111b,#11111b textbox=#a6e3a1,#11111b acttextbox=#a6e3a1,#11111b label=#a6e3a1,#11111b listbox=#a6e3a1,#11111b actlistbox=#a6e3a1,#11111b sellistbox=#a6e3a1,#11111b actsellistbox=#11111b,#a6e3a1";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Both modules are taken out of the s2idle path before suspend and restored on resume.
  # amdxdna: since 2026-05-25 (22723ff), against a PSP hang on wake.
  # mt7925e: same trick, added 2026-06-26 (c650b16) after a suspend froze with the journal ending
  # at "PM: suspend entry (s2idle)" right after the WiFi teardown, then reverted the same day
  # (e614221) to see whether 7.1.1 handled it, leaving the note "restore if a suspend hang with
  # WiFi teardown recurs". It recurred on 2026-08-06 19:16 with that exact signature, so it is
  # back — as a test, not a known fix. Caveat: the WiFi teardown precedes every suspend, including
  # the 51 that resumed fine, so its presence in the failing one proves nothing on its own.
  # Drop it again if a hang recurs with it active. See debug-session-2026-08-06.2.md.
  powerManagement.powerDownCommands = ''
    ${pkgs.kmod}/bin/rmmod amdxdna 2>/dev/null || true
    ${pkgs.kmod}/bin/rmmod mt7925e 2>/dev/null || true
  '';

  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/modprobe amdxdna
    ${pkgs.kmod}/bin/modprobe mt7925e
  '';

  system.stateVersion = "25.05";

}
