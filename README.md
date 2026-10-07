# NixOS Configuration

Personal NixOS configuration for Framework AMD AI 300 Series (x86\_64-linux).

## Setup

```sh
git config core.hooksPath .githooks  # do this first — see the warning below
cp private.nix.example private.nix
# Fill in private.nix with your values
git add --force private.nix  # makes it visible to nix flake (stays gitignored)
```

> **Set `core.hooksPath` before the first commit.** It lives in `.git/config`, which is
> never tracked or pushed, so a fresh clone starts with the hooks disabled. The
> force-added `private.nix` is kept out of history by the pre-commit hook alone — without
> it, the next commit publishes the file and everything in it.

> After the first commit, the post-commit hook keeps `private.nix` staged automatically.

## Structure

```
~/.nixos/
├── flake.nix                    # Flake inputs, the user's name; loads ./modules
├── flake.lock
├── hardware-configuration.nix   # Auto-generated hardware config
├── private.nix.example          # Private config template
├── private.nix                  # Private values — gitignored, not in repo
├── modules/
│   ├── default.nix              # The one list of imports
│   ├── core.nix                 # Locale, user, sudo, Nix settings
│   ├── hardware.nix             # Graphics, radios, kernel, LUKS
│   ├── power.nix                # TLP, scx, suspend hooks, battery, Wi-Fi power save
│   ├── desktop.nix              # GDM, PipeWire, portals, oo7, desktop services
│   ├── session.nix              # User services of the niri session (Quickshell, hypridle, …)
│   ├── background-apps.nix      # Thunderbird and Signal without a window
│   ├── network.nix              # NetworkManager, resolved, Avahi, firewall
│   ├── wireguard.nix            # wg0, wg-auto and its kill switch
│   ├── packages.nix             # System packages and programs
│   ├── fonts.nix                # Fonts and the default families
│   ├── printers.nix             # Xerox Phaser 3020
│   ├── littlesnitch.nix         # Little Snitch application firewall
│   ├── script.nix               # Helper: a file from scripts/ as a command
│   └── optional/                # Not imported: llm.nix, dlna.nix
├── scripts/                     # Shell scripts the modules install, shellchecked at build
├── notes/                       # Why things are the way they are, one file per topic
└── .githooks/
    ├── pre-commit               # Nixfmt on what is staged; auto-unstages private.nix
    ├── post-commit              # Re-stages private.nix so nix flake can find it
    └── pre-push                 # Refuses a push that carries private.nix
```

`flake.nix` loads `./modules`, and `modules/default.nix` is the only list of
imports, the flake inputs' modules included; `optional/llm.nix` and
`optional/dlna.nix` sit there commented out. The order of that list is the
order lists are merged in (substituters, tmpfiles rules). `private.nix` is
read once, in `flake.nix`, and reaches the modules as the `private`
argument; the user's name is set there too and reaches them as `user`.

Comments in the modules are kept to a line or two. The history behind a
setting, with dates and measurements, is in `notes/`.

## Flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` (unstable) | Main package set |
| `nixos-hardware` | Hardware quirks for Framework AMD AI 300 |
| `niri` | Niri compositor module + overlay, from `epireyn/niri-flake` |
| `nix-index-database` | `comma` command runner |
| `claude-code` | Claude Code CLI via dedicated overlay |
| `littlesnitch` | Little Snitch application firewall for Linux |
| `chaotic` | Proton CachyOS for Steam, from Chaotic Nyx |

## Desktop

- **Compositor:** [niri](https://github.com/YaLTeR/niri) (Wayland, scrolling tiling)
- **Status bar:** Quickshell (config in `~/.dotfiles/.config/quickshell`)
- **Idle daemon:** Hypridle
- **Lock screen:** Quickshell (same config as the status bar)
- **Wallpaper daemon:** AWWW
- **Blue-light filter:** Gammastep (`-l 50.5:22.0`, 6500K→4500K)
- **Notifications:** Quickshell (same config as the status bar)
- **Terminal:** Ghostty
- **Launcher:** Fuzzel
- **File manager:** Nautilus (opens Ghostty via `nautilus-open-any-terminal`)
- **Fonts:** Adwaita Sans, JetBrainsMono Nerd Font, Noto Sans CJK

## Audio / Video

- PipeWire with ALSA and PulseAudio compatibility
- Full FFmpeg (`ffmpeg-full`) with mpv override
- MPV with the uosc and mpris scripts
- GStreamer plugins (base, good, bad, ugly, libav)

## Hardware

- AMD GPU with OpenCL from ROCm (`rocmPackages.clr`)
- Bluetooth with battery level reporting
- YubiKey support (yubikey-manager, yubikey-touch-detector)
- SANE scanner support
- Fingerprint reader (fprintd)
- TLP power management

## Networking

- NetworkManager with wpa\_supplicant backend
- systemd-resolved for DNS
- Avahi (mDNS/zeroconf)
- WireGuard VPN (`wg0`, endpoint configured in `private.nix`): brought up on
  every network that is not trusted in `private.nix`, with a kill switch
- Spotify LAN sync and Miracast ports open in firewall
- Little Snitch outbound application firewall (`modules/littlesnitch.nix`)

## Local AI

> Currently disabled — the `./optional/llm.nix` import is commented out in `modules/default.nix`.

- Ollama (Vulkan backend) — `http://localhost:11434`
- Open WebUI — `http://localhost:8080` (no auth, local only)

## Notable packages

- **Shell:** Fish + Starship + tmux
- **Editor:** Micro (default), Helix
- **Git:** git + lazygit + diff-so-fancy + git-filter-repo
- **AI:** Claude Code
- **Security:** KeePassXC, gocryptfs, WireGuard
- **Containers:** Podman (Docker-compatible)
- **Gaming:** Steam (with GameScope and Proton CachyOS), Distrobox
- **Communication:** Signal, Discord, Thunderbird, Tuba
- **Productivity:** Obsidian, OnlyOffice, Firefox, Google Chrome

## Applying changes

```sh
# Using nh (recommended)
nh os switch

# Or with nixos-rebuild directly
sudo nixos-rebuild switch --flake ~/.nixos#nixos
```

Flake path is set via `programs.nh.flake` in `modules/packages.nix`, so
`NH_OS_FLAKE` is configured automatically.
