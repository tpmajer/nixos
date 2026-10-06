# Signal's window. With none running signal-background is started first, so
# that the instance whose window comes up stays when the window is closed.
running() {
  lock=$(readlink "$HOME/.config/Signal/SingletonLock" 2> /dev/null) \
    && grep -qs signal-desktop "/proc/${lock##*-}/cmdline"
}
if ! running; then
  systemctl --user start signal-background.service
  # A second instance that comes before the lock is taken would be the first.
  for _ in $(seq 50); do
    running && break
    sleep 0.1
  done
fi
exec "$SIGNAL_BIN" "$@"
