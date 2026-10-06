# GeForce NOW with Wi-Fi power save off for as long as it runs.
systemctl start wifi-nopowersave.service
trap 'systemctl stop wifi-nopowersave.service' EXIT
flatpak run --branch=master --arch=x86_64 --command=GeForceNOW com.nvidia.geforcenow "$@"
