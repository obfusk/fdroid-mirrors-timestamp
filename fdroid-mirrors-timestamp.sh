#!/bin/bash
set -euo pipefail

mirrors=(
  https://f-droid.org
  https://fdroid.tetaneutral.net/fdroid
  https://ftp.agdsn.de/fdroid                   # primary
  https://ftp.fau.de/fdroid
  https://ftp.lysator.liu.se/pub/fdroid         # primary
  https://mirror.cyberbits.eu/fdroid
  https://mirror.fcix.net/fdroid
  https://mirror.ossplanet.net/fdroid
  https://plug-mirror.rcac.purdue.edu/fdroid    # primary
)

onion_mirrors=(
  http://fdroidorg6cooksyluodepej4erfctzk7rrjpjbbr6wx24jh3lqyfwyd.onion/fdroid
  http://ftpfaudev4triw2vxiwzf4334e3mynz7osqgtozhbc77fixncqzbyoyd.onion/fdroid
  http://lysator7eknrfl47rlyxvgeamrv7ucefgrrlhk7rouv3sna25asetwid.onion/pub/fdroid
)

check_mirror() {
  local mirror="$1" onion="$2"
  if [ "$onion" = --onion ]; then
    curl=( curl --socks5-hostname localhost:9050 -s )
  else
    curl=( curl -s )
  fi
  for component in repo archive; do
    if ts="$( "${curl[@]}" "$mirror"/"$component"/entry.json \
              | jq -r .timestamp 2>/dev/null )"; then
      echo "$mirror [$component]:"
      ts="$(date +'%FT%T %Z' -d @"$(( "$ts" / 1000 ))")"
      if [ "$mirror" = "${mirrors[0]}" ]; then
        if [ "$component" = repo ]; then
          fdroid_repo_ts="$ts"
        else
          fdroid_archive_ts="$ts"
        fi
      elif [ -t 1 ] && [[ ( "$component" == repo && \
                            "$ts" != "$fdroid_repo_ts" ) || \
                          ( "$component" == archive && \
                            "$ts" != "$fdroid_archive_ts" ) ]]; then
        ts="\033[0;31m$ts\033[0m"
      fi
      echo -e "$ts"
    fi
  done
  echo
}

for mirror in "${mirrors[@]}"; do
  check_mirror "$mirror"
done

if [ "$2" = --onions ]; then
  for mirror in "${onion_mirrors[@]}"; do
    check_mirror "$mirror" --onion
  done
fi
