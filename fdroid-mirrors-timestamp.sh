#!/bin/bash
# SPDX-FileCopyrightText: 2023 FC Stegerman <flx@obfusk.net>
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

statuspage_yml=fdroid-statuspage-deployment/group_vars/all.yml
mirrors=() onion_mirrors=() unofficial_mirrors=() unofficial_onion_mirrors=()
check_onion=no check_unofficial=no exitcode=0
usage='Usage: fdroid-mirrors-timestamp.sh [--onion] [--unofficial]'

check_mirror() {
  local mirror="$1" onion="${2:-}"
  if [ "$onion" = --onion ]; then
    curl=( curl --socks5-hostname localhost:9050 --connect-timeout 5 -s )
  else
    curl=( curl -s )
  fi
  for component in repo archive; do
    echo "$mirror [$component]:"
    if ts="$( "${curl[@]}" "$mirror"/"$component"/entry.json \
              | jq -r .timestamp 2>/dev/null )"; then
      ts="$(date +'%FT%T %Z' -d @"$(( "$ts" / 1000 ))")"
      if [ "$mirror" = "${mirrors[0]}" ]; then
        if [ "$component" = repo ]; then
          fdroid_repo_ts="$ts"
        else
          fdroid_archive_ts="$ts"
        fi
        [ -t 1 ] && ts="\033[0;36m$ts\033[0m"
      elif [[ ( "$component" == repo && "$ts" != "$fdroid_repo_ts" ) || \
              ( "$component" == archive && "$ts" != "$fdroid_archive_ts" ) ]]; then
        exitcode=2
        [ -t 1 ] && ts="\033[0;31m$ts\033[0m"
      else
        [ -t 1 ] && ts="\033[0;32m$ts\033[0m"
      fi
      echo -e "$ts"
    else
      err=missing
      if [ "$component" = repo ] || [ "$mirror" = "${mirrors[0]}" ]; then
        exitcode=2
        [ -t 1 ] && err="\033[0;31m$err\033[0m"
      else
        [ -t 1 ] && err="\033[0;33m$err\033[0m"
      fi
      echo -e "$err"
      if [ "$mirror" = "${mirrors[0]}" ]; then
        exit 3
      fi
    fi
  done
  echo
}

while read -r url; do
  if [[ "$url" == *.onion* ]]; then
    onion_mirrors+=( "$url" )
  else
    mirrors+=( "$url" )
  fi
done < <( yq -r < "$statuspage_yml" '.mirrors[] | select(.official) | .base_url' | sort )

while read -r url; do
  if [[ "$url" == *.onion* ]]; then
    unofficial_onion_mirrors+=( "$url" )
  else
    unofficial_mirrors+=( "$url" )
  fi
done < <( yq -r < "$statuspage_yml" '.mirrors[] | select(.official | not) | .base_url' | sort )

for arg in "$@"; do
  case "$arg" in
    --onion|-o)
      check_onion=yes
    ;;
    --unofficial|-u)
      check_unofficial=yes
    ;;
    --help)
      echo "$usage" >&2
      exit
    ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "$usage" >&2
      exit 1
    ;;
  esac
done

echo "==> Official mirrors"
echo
for mirror in "${mirrors[@]}"; do
  check_mirror "$mirror"
done

if [ "$check_unofficial" = yes ]; then
  echo "==> Unofficial mirrors"
  echo
  for mirror in "${unofficial_mirrors[@]}"; do
    check_mirror "$mirror"
  done
fi

if [ "$check_onion" = yes ]; then
  echo "==> Official onion mirrors"
  echo
  for mirror in "${onion_mirrors[@]}"; do
    check_mirror "$mirror" --onion
  done
  if [ "$check_unofficial" = yes ]; then
    echo "==> Unofficial onion mirrors"
    echo
    for mirror in "${unofficial_onion_mirrors[@]}"; do
      check_mirror "$mirror" --onion
    done
  fi
fi

exit "$exitcode"
