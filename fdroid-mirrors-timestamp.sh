#!/bin/bash
set -euo pipefail

check_onion=no check_unofficial=no exitcode=0

usage='Usage: fdroid-mirrors-timestamp.sh [--onion] [--unofficial]'

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

unofficial_mirrors=(
  https://bubu1.eu/fdroid
  https://cloudflare.f-droid.org
  https://fdroid.astra.in.ua/fdroid
  https://forksystems.mm.fcix.net/fdroid
  https://ftp.gwdg.de/pub/android/fdroid
# https://ftp.osuosl.org/pub/fdroid
  https://ftp.snt.utwente.nl/pub/software/fdroid
  https://mirror.albony.xyz/fdroid
  https://mirror.cxserv.de/fdroid
  https://mirror.freedif.org/fdroid
  https://mirror.kumi.systems/fdroid
  https://mirror.librelabucm.org/fdroid
# https://mirror01.komogoto.com/fdroid
  https://mirrors.dotsrc.org/fdroid
  https://mirrors.jevincanders.net/fdroid
  https://mirrors.nju.edu.cn/fdroid
  https://mirrors.tuna.tsinghua.edu.cn/fdroid
  https://opencolo.mm.fcix.net/fdroid
  https://southfront.mm.fcix.net/fdroid
  https://uvermont.mm.fcix.net/fdroid
  https://ziply.mm.fcix.net/fdroid
)

unofficial_onion_mirrors=(
  http://mirror.ossplanetnyou5xifr6liw5vhzwc2g2fmmlohza25wwgnnaw65ytfsad.onion/fdroid
)

check_mirror() {
  local mirror="$1" onion="${2:-}"
  if [ "$onion" = --onion ]; then
    curl=( curl --socks5-hostname localhost:9050 -s )
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
