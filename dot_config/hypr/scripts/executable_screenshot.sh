#!/usr/bin/env bash
# usage: screenshot.sh area|full
# copies the image to the clipboard and uploads it to bomzh.fm; the notification
# shows the url and opens it when clicked. nothing is kept on disk: the image only
# exists in $XDG_RUNTIME_DIR (ram) until the upload finishes.
# api key lives in ~/.secrets/bomzh.env as API=xxxx (chmod 600, outside the
# dotfiles repo). without a key the image is only copied.
set -euo pipefail

mode="${1:-area}"
envfile="${BOMZH_ENV:-$HOME/.secrets/bomzh.env}"
file="$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}" "screenshot-XXXXXX.png")"
trap 'rm -f "$file"' EXIT

case "$mode" in
    area) geom="$(slurp)" || exit 0; grim -g "$geom" "$file" ;; # esc in slurp just cancels
    full) grim "$file" ;;
    *) echo "unknown mode: $mode" >&2; exit 1 ;;
esac

wl-copy --type image/png < "$file"

[[ -f "$envfile" ]] || { notify-send "Screenshot copied" "no $envfile, not uploaded"; exit 0; }

if [[ "$(stat -c %a "$envfile")" != 600 ]]; then
    notify-send -u critical "Screenshot copied" "not uploaded: $envfile must be chmod 600"
    exit 1
fi

# parse instead of sourcing so the file can't run code; strips optional quotes
key="$(sed -n 's/^[[:space:]]*API[[:space:]]*=[[:space:]]*//p' "$envfile" | tail -n1 | tr -d "\"'[:space:]")"
[[ -n "$key" ]] || { notify-send "Screenshot copied" "no API= in $envfile, not uploaded"; exit 0; }

# curl reads the header from stdin (-H @-) so the key isn't visible in ps.
# success and error bodies are both plain text, so split off the status code
resp="$(printf 'X-Api-Key: %s\n' "$key" | curl -sS --max-time 30 -H @- -F "image=@$file" \
    -w '\n%{http_code}' https://bomzh.fm/upload 2>&1)" || true
code="${resp##*$'\n'}"
link="$(tr -d '[:space:]' <<< "${resp%$'\n'*}")"

rm -f "$file"

if [[ "$code" != 2* ]]; then
    notify-send -u critical "Upload failed ($code)" "${link:-no response}
image is still on the clipboard"
    exit 1
fi

# default = clicking the notification itself; --wait blocks until it's clicked or closed
action="$(notify-send -A default=Open -A open="Open link" --wait "Screenshot uploaded" "$link")" || true
if [[ "$action" == default || "$action" == open ]]; then
    xdg-open "$link" >/dev/null 2>&1
fi
