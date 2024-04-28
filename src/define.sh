#!/usr/bin/env bash
set -Eeuo pipefail

: "${MANUAL:=""}"
: "${VERSION:=""}"
: "${DETECTED:=""}"
: "${PLATFORM:="ARM64"}"

getLink() {

  local id="$1"
  local url=""
  local host="https://dl.bobpony.com"

  case "${id,,}" in
    "win11${PLATFORM,,}")
      url="$host/windows/11/en-us_windows_11_23h2_${PLATFORM,,}.iso"
      ;;
    "win10${PLATFORM,,}")
      url="$host/windows/10/en-us_windows_10_22h2_${PLATFORM,,}.iso"
      ;;
  esac

  echo "$url"
  return 0
}

parseVersion() {

  [ -z "$VERSION" ] && VERSION="win11"

  if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
    VERSION="${VERSION:1:-1}"
  fi

  case "${VERSION,,}" in
    "11" | "win11")
      VERSION="win11${PLATFORM,,}"
      ;;
    "10" | "win10")
      VERSION="win10${PLATFORM,,}"
      ;;
  esac

  return 0
}

printVersion() {

  local id="$1"
  local desc="$2"

  [[ "$id" == "win10"* ]] && desc="Windows 10 for ${PLATFORM}"
  [[ "$id" == "win11"* ]] && desc="Windows 11 for ${PLATFORM}"

  [ -z "$desc" ] && desc="Windows for ${PLATFORM}"

  echo "$desc"
  return 0
}

getName() {

  local file="$1"
  local desc="$2"

  [[ "${file,,}" == "win11"* ]] && desc="Windows 11 for ${PLATFORM}"
  [[ "${file,,}" == "win10"* ]] && desc="Windows 10 for ${PLATFORM}"
  [[ "${file,,}" == *"windows11"* ]] && desc="Windows 11 for ${PLATFORM}"
  [[ "${file,,}" == *"windows10"* ]] && desc="Windows 10 for ${PLATFORM}"
  [[ "${file,,}" == *"windows_11"* ]] && desc="Windows 11 for ${PLATFORM}"
  [[ "${file,,}" == *"windows_10"* ]] && desc="Windows 10 for ${PLATFORM}"

  [ -z "$desc" ] && desc="Windows for ${PLATFORM}"

  echo "$desc"
  return 0
}

getVersion() {

  local name="$1"
  local detected=""

  [[ "${name,,}" == *"windows 11"* ]] && detected="win11${PLATFORM,,}"
  [[ "${name,,}" == *"windows 10"* ]] && detected="win10${PLATFORM,,}"

  echo "$detected"
  return 0
}

return 0
