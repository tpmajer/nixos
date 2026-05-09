# NixOS Configuration

Personal NixOS configuration for Framework AMD AI 300 Series (x86\_64-linux).

## Setup

```sh
cp private.nix.example private.nix
# Fill in private.nix with your values
git add --force private.nix  # makes it visible to nix flake (stays gitignored)
```

## Structure

```
~/.nixos/
├── flake.nix                    # Flake inputs and system definition
├── flake.lock
├── system.nix                   # Boot, hardware, services, users, Nix settings
├── packages.nix                 # System packages and programs
├── fonts.nix                    # Fonts
├── network.nix                  # Networking, WireGuard VPN, firewall
├── user-services.nix            # Systemd user services (Waybar, Hypridle, AWWW, Gammastep)
├── hardware-configuration.nix   # Auto-generated hardware config
├── gdm.nix                      # GDM config (currently disabled)
└── dlna.nix                     # DLNA server config (currently disabled)
```

## Flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` (unstable) | Main package set |
| `nixos-hardware` | Hardware quirks for Framework AMD AI 300 |
| `musnix` | Low-latency audio (available but disabled) |
| `niri` | Niri Wayland compositor + overlay |
| `nix-index-database` | `comma` command runner |
| `claude-code` | Claude Code CLI via dedicated overlay |

## Desktop

- **Compositor:** [niri](https://github.com/YaLTeR/niri) (Wayland, scrolling tiling)
- **Status bar:** Waybar
- **Idle daemon:** Hypridle + Hyprlock
- **Wallpaper daemon:** AWWW
- **Blue-light filter:** Gammastep (Warsaw coordinates, 6500K→4500K)
- **Notifications:** Mako
- **Terminal:** Ghostty
- **Launcher:** Fuzzel
- **File manager:** Nautilus (opens Ghostty via `nautilus-open-any-terminal`)

## Audio / Video

- PipeWire with ALSA and PulseAudio compatibility
- Full FFmpeg (`ffmpeg-full`) with mpv override
- MPV with uosc script
- GStreamer plugins (base, good, bad, ugly, libav)

## Hardware

- AMD GPU with ROCm (OpenCL via `RUSTICL_ENABLE=radeonsi`, Vulkan via `RADV`)
- Bluetooth with battery level reporting
- YubiKey support (yubikey-manager, yubikey-touch-detector)
- SANE scanner support
- Fingerprint reader (fprintd)
- TLP power management

## Networking

- NetworkManager with wpa\_supplicant backend
- systemd-resolved for DNS
- Avahi (mDNS/zeroconf)
- WireGuard VPN (`wg0`, manual start, endpoint configured in `private.nix`)
- Spotify LAN sync and Cast ports open in firewall

## Notable packages

- **Shell:** Fish + Starship + tmux
- **Editor:** Micro (default), Helix
- **Git:** git + lazygit + diff-so-fancy (patched) + git-filter-repo
- **AI:** Claude Code
- **Security:** KeePassXC, GnuPG (pinentry-all), gocryptfs, WireGuard
- **Containers:** Podman (Docker-compatible)
- **Gaming:** Steam (with GameScope), Protonup-Qt, Distrobox
- **Communication:** Signal, Discord, Thunderbird, Tuba
- **Productivity:** Obsidian, OnlyOffice, Firefox, Google Chrome

## Applying changes

```sh
# Using nh (recommended)
nh os switch

# Or with nixos-rebuild directly
sudo nixos-rebuild switch --flake ~/.nixos#nixos
```

Flake path is set via `programs.nh.flake` in `packages.nix`, so `NH_OS_FLAKE` is configured automatically.
