# Whether a Signal is running: the lock links to a name that ends in its PID.
lock=$(readlink "$HOME/.config/Signal/SingletonLock" 2> /dev/null) \
  && grep -qs signal-desktop "/proc/${lock##*-}/cmdline"
