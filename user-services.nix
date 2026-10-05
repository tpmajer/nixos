# /etc/nixos/user-services.nix

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{

  # Keep every other user service at the 8 MiB default; only oo7-daemon needs the raised
  # ceiling that user@.service now provides (see the mlock comment in system.nix).
  systemd.user.settings.Manager.DefaultLimitMEMLOCK = "8M";

  systemd.user.services = {

    # mlockall needs the whole address space (VmSize ~1.66 GiB, mostly PROT_NONE malloc arenas)
    # to fit under RLIMIT_MEMLOCK, not just the ~10 MiB it pins. See the comment in system.nix.
    oo7-daemon.serviceConfig.LimitMEMLOCK = "2G";

    # path = [ ] keeps the session PATH (from niri) instead of a Nix-built one, so
    # the bar's scripts and click commands (nmcli, wpctl, ghostty, niri msg, ...)
    # resolve as in the shell.
    quickshell = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "Quickshell bar";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.quickshell}/bin/quickshell";
        # always, not on-failure: it is the session lock too. If it goes while
        # the session is locked, even cleanly (qs kill, SIGTERM), niri keeps the
        # session locked with nothing to unlock it; the next process locks
        # again by its marker. systemctl stop still stops it.
        Restart = "always";
        RestartSec = "2s";
      };
      path = lib.mkForce [ ];
    };

    hypridle = {
      path = lib.mkForce [ ];
      after = [ "niri.service" ];
      wantedBy = lib.mkForce [ "niri.service" ];
    };

    awww-daemon = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "AWWW Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      path = [ pkgs.awww ];
    };

    gammastep = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "Gammastep Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.gammastep}/bin/gammastep -l 50.5:22.0 -t 6500:4500 -m wayland -v";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # The packaged unit ships in $out/share/systemd/user, but NixOS's
    # systemd.packages only scans etc/systemd/user and lib/systemd/user
    # (nixos/lib/systemd-lib.nix:441), so adding the package there would be a
    # no-op — define the unit here instead. Bound to niri.service like the rest
    # of the session services, not to the upstream graphical-session.target.
    # The agent takes ~/.config/openlogi/agent.lock and exits 0 if another
    # instance already holds it, so Restart=on-failure won't fight the GUI.
    openlogi-agent = {
      after = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      description = "OpenLogi background agent (Logitech HID++ device control)";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.openlogi}/bin/openlogi-agent";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    "app-com.mitchell.ghostty" = {
      after = [
        "graphical-session.target"
        "niri.service"
      ];
      wantedBy = [ "niri.service" ];
      description = "Ghostty Service";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.ghostty}/bin/ghostty --gtk-single-instance=true --initial-window=false";
        Restart = "on-failure";
        RestartSec = "2s";
      };
      path = lib.mkForce [ ];
    };

    # Thunderbird without a window, so that new mail is notified of while the
    # client is closed. The account is under Google's Advanced Protection: no
    # app passwords, and only a few clients are let at the mail at all, so a
    # small IMAP watcher is not an option, while Thunderbird is signed in
    # already. Measured on 2026-10-04: about 330 MiB, and a notification with
    # "Mark as Read" and "Delete".
    # Thunderbird runs one instance per profile, so the thunderbird wrapper
    # below stops this before the window comes up and starts it again once
    # the window is closed. The condition is for a start with the window up.
    thunderbird-headless = {
      after = [
        "niri.service"
        "quickshell.service"
      ];
      wantedBy = [ "niri.service" ];
      description = "Thunderbird without a window, for new mail notifications";
      serviceConfig = {
        Type = "simple";
        ExecCondition = pkgs.writeShellScript "thunderbird-no-window-up" ''
          ! ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -f 'bin/\.thunderbird-wrapped_' > /dev/null
        '';
        ExecStart = "${pkgs.thunderbird}/bin/thunderbird --headless";
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };

  };

  # Over the package's own bin/thunderbird, which the launcher entry, mailto
  # links and the shell all run: the window in place of the instance without
  # one. With a window up already this is only a message to it.
  environment.systemPackages = [
    (lib.hiPrio (
      pkgs.writeShellScriptBin "thunderbird" ''
        unit=thunderbird-headless.service
        if ! systemctl --user is-active --quiet "$unit" \
          && pgrep -u "$(id -u)" -f 'bin/\.thunderbird-wrapped_' > /dev/null; then
          exec ${pkgs.thunderbird}/bin/thunderbird "$@"
        fi
        systemctl --user stop "$unit"
        # Thunderbird has no setting for the folder to start in: the first
        # tab comes back from session.json with the folder it was closed on.
        # Point that tab at the Inbox of the same account and select it; the
        # other tabs stay as they were.
        for session in "$HOME"/.thunderbird/*/session.json; do
          [ -f "$session" ] || continue
          ${pkgs.jq}/bin/jq -c '
            (.windows[]?.tabs | select(.tabs | any(.state.firstTab == true))) |= (
              .selectedIndex = (.tabs | map(.state.firstTab == true) | index(true))
              | (.tabs[] | select(.state.firstTab == true) | .state.folderURI)
                |= sub("^(?<server>imap://[^/]+)/.*$"; "\(.server)/INBOX")
            )' "$session" > "$session.inbox" \
            && mv "$session.inbox" "$session" \
            || rm -f "$session.inbox"
        done
        ${pkgs.thunderbird}/bin/thunderbird "$@"
        status=$?
        systemctl --user start "$unit"
        exit $status
      ''
    ))
  ];

}
