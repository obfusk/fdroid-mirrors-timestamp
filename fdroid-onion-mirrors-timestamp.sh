#!/bin/bash
set -e
mirrors=(
  http://fdroidorg6cooksyluodepej4erfctzk7rrjpjbbr6wx24jh3lqyfwyd.onion/fdroid
  http://ftpfaudev4triw2vxiwzf4334e3mynz7osqgtozhbc77fixncqzbyoyd.onion/fdroid
  http://lysator7eknrfl47rlyxvgeamrv7ucefgrrlhk7rouv3sna25asetwid.onion/pub/fdroid
)
for mirror in "${mirrors[@]}"; do
  for component in repo archive; do
    if ts="$(curl --socks5-hostname localhost:9050 -s "$mirror"/"$component"/entry.json | jq -r .timestamp 2>/dev/null)"; then
      echo "$mirror [$component]:"
      date +'%FT%T' -d @"$(( "$ts" / 1000 ))"
    fi
  done
  echo
done
