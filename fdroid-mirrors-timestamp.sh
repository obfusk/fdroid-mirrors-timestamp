#!/bin/bash
set -e
mirrors=(
  https://f-droid.org
  https://fdroid.tetaneutral.net/fdroid
  https://ftp.agdsn.de/fdroid
  https://ftp.fau.de/fdroid
  https://ftp.lysator.liu.se/pub/fdroid
  https://mirror.cyberbits.eu/fdroid
  https://mirror.fcix.net/fdroid
  https://mirror.ossplanet.net/fdroid
  https://plug-mirror.rcac.purdue.edu/fdroid
)
for mirror in "${mirrors[@]}"; do
  for component in repo archive; do
    if ts="$(curl -s "$mirror"/"$component"/entry.json | jq -r .timestamp 2>/dev/null)"; then
      echo "$mirror [$component]:"
      date -d @"$(( "$ts" / 1000 ))"
    fi
  done
  echo
done
