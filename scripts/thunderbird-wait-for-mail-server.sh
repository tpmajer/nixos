# Waits for the mail server before thunderbird-headless starts, so that its
# first mail check does not fail: twice 2 s apart, not while wg0 is coming up,
# and for 60 s at most. Always passes. See notes/background-apps.md.
answers=0
while [ "$SECONDS" -lt 60 ]; do
  if [ "$(systemctl is-active wg-quick-wg0.service)" != activating ] \
    && timeout 3 bash -c ': < /dev/tcp/imap.gmail.com/993' 2> /dev/null; then
    answers=$((answers + 1))
    [ "$answers" -ge 2 ] && exit 0
  else
    answers=0
  fi
  sleep 2
done
echo "imap.gmail.com did not answer within 60 s: starting without it" >&2
exit 0
