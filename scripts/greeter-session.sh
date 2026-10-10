# What greetd starts, the login screen or a session, with its output in the
# journal: greetd connects it to the VT, where it shows between compositors.
#   greeter-session <identifier> <command> [argument...]

# No cursor on that VT either.
printf '\033[?25l'

identifier=$1
shift
exec systemd-cat --identifier="$identifier" -- "$@"
