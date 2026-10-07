# Whether a Thunderbird is running, with a window or without one.
pgrep -u "$(id -u)" -f 'bin/\.thunderbird-wrapped_' > /dev/null
