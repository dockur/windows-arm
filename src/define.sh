#!/usr/bin/env bash
set -Eeuo pipefail

: "${VERIFY:=""}"
: "${MANUAL:=""}"
: "${VERSION:=""}"
: "${DETECTED:=""}"
: "${PLATFORM:="ARM64"}"

MIRRORS=2

parseVersion() {

  [ -z "$VERSION" ] && VERSION="win11"

  if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
    VERSION="${VERSION:1:-1}"
  fi

  case "${VERSION,,}" in
    "11" | "win11" | "windows11" | "windows 11" )
      VERSION="win11${PLATFORM,,}"
      ;;
    "10" | "win10" | "windows10" | "windows 10" )
      VERSION="win10${PLATFORM,,}"
      ;;
  esac

  return 0
}

printVersion() {

  local id="$1"
  local desc="$2"

  case "${id,,}" in
    "win10"* ) desc="Windows 10" ;;
    "win11"* ) desc="Windows 11" ;;
  esac

  if [ -z "$desc" ]; then
    desc="Windows"
    [[ "${PLATFORM,,}" != "x64" ]] && desc="$desc for ${PLATFORM}"
  fi

  echo "$desc"
  return 0
}

printEdition() {

  local id="$1"
  local desc="$2"
  local result=""
  local edition=""

  result=$(printVersion "$id" "x")
  [[ "$result" == "x" ]] && echo "$desc" && return 0

  case "${id,,}" in
    "win10"* )
      edition="Pro"
      ;;
    "win11"* )
      edition="Pro"
      ;;
  esac

  [ -n "$edition" ] && result="$result $edition"

  echo "$result"
  return 0
}

fromFile() {

  local id=""
  local desc="$1"
  local file="${1,,}"

  case "${file/ /_}" in
    "win10"*| "win_10"* | *"windows10"* | *"windows_10"* )
      id="win10${PLATFORM,,}"
      ;;
    "win11"* | "win_11"* | *"windows11"* | *"windows_11"* )
      id="win11${PLATFORM,,}"
      ;;
  esac

  if [ -n "$id" ]; then
    desc=$(printVersion "$id" "$desc")
  fi

  echo "$desc"
  return 0
}

fromName() {

  local id=""
  local name="$1"

  case "${name,,}" in
    *"windows 10"* ) id="win10${PLATFORM,,}" ;;
    *"windows 11"* ) id="win11${PLATFORM,,}" ;;
  esac

  echo "$id"
  return 0
}

getVersion() {

  local id
  local name="$1"

  id=$(fromName "$name")

  echo "$id"
  return 0
}

switchEdition() {
  return 0
}

isESD() {

  local id="$1"

  case "${id,,}" in
    "win11${PLATFORM,,}" ) return 0 ;;
    "win10${PLATFORM,,}" ) return 0 ;;
  esac

  return 1
}

isMido() {
  return 1
}

getLink1() {

  # Fallbacks for users who cannot connect to the Microsoft servers

  local id="$1"
  local ret="$2"
  local url=""
  local sum=""
  local host="https://dl.bobpony.com/windows"

  case "${id,,}" in
    "win11${PLATFORM,,}")
      sum=""
      url="$host/windows/11/en-us_windows_11_23h2_${PLATFORM,,}.iso"
      ;;
    "win10${PLATFORM,,}")
      sum=""
      url="$host/windows/10/en-us_windows_10_22h2_${PLATFORM,,}.iso"
      ;;
  esac

  [ -z "$ret" ] && echo "$url" || echo "$sum"
  return 0
}

getLink2() {

  # Fallbacks for users who cannot connect to the Microsoft servers

  local id="$1"
  local ret="$2"
  local url=""
  local sum=""
  local host="https://drive.massgrave.dev"

  case "${id,,}" in
    "win11${PLATFORM,,}")
      sum=""
      url="$host/SW_DVD9_Win_Pro_11_23H2.2_Arm64_English_Pro_Ent_EDU_N_MLF_X23-68023.ISO"
      ;;
    "win10${PLATFORM,,}")
      sum=""
      url="$host/SW_DVD9_Win_Pro_10_22H2.15_Arm64_English_Pro_Ent_EDU_N_MLF_X23-67223.ISO"
      ;;
  esac

  [ -z "$ret" ] && echo "$url" || echo "$sum"
  return 0
}

getLink() {

  local url=""
  local id="$2"
  local func="getLink$1"

  if [ "$1" -gt 0 ] && [ "$1" -le "$MIRRORS" ]; then
    url=$($func "$id" "")
  fi

  echo "$url"
  return 0
}

getHash() {

  local sum=""
  local id="$2"
  local func="getLink$1"

  if [ "$1" -gt 0 ] && [ "$1" -le "$MIRRORS" ]; then
    sum=$($func "$id" "sum")
  fi

  echo "$sum"
  return 0
}

validVersion() {

  local id="$1"
  local url

  isESD "$id" && return 0
  isMido "$id" && return 0

  for ((i=1;i<=MIRRORS;i++)); do

    url=$(getLink "$i" "$id")
    [ -n "$url" ] && return 0

  done

  return 1
}

return 0
