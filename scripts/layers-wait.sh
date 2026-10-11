# Waits until niri has a layer surface for each pattern, asking that many
# times, 10 ms apart.
#   layers-wait <times> <pattern>...

times=$1
shift

for _ in $(seq "$times"); do
    layers=$(niri msg layers 2>/dev/null)
    missing=
    for pattern in "$@"; do
        printf '%s\n' "$layers" | grep -Eq "$pattern" || missing=1
    done
    [ -z "$missing" ] && exit 0
    sleep 0.01
done
exit 1
