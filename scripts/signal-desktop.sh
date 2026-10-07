# Signal's window. With none running signal-background is started first, so
# that the instance whose window comes up stays when the window is closed.
if ! signal-running; then
  systemctl --user start signal-background.service
  # A second instance that comes before the lock is taken would be the first.
  for _ in $(seq 50); do
    signal-running && break
    sleep 0.1
  done
fi
exec "$SIGNAL_BIN" "$@"
