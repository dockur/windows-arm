#!/usr/bin/env bash
set -Eeuo pipefail

: "${MANUAL:=""}"
: "${VERSION:=""}"
: "${DETECTED:=""}"
: "${PLATFORM:="ARM64"}"

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

validVersion() {

  local id="$1"

  case "${id,,}" in
    "win11${PLATFORM,,}")
      return 0
      ;;
    "win10${PLATFORM,,}")
      return 0
      ;;
  esac

  return 1
}

isESD() {

  local id="$1"

  case "${id,,}" in
    "win11${PLATFORM,,}")
      return 0
      ;;
    "win10${PLATFORM,,}")
      return 0
      ;;
  esac

  return 1
}

printVersion() {

  local id="$1"
  local desc="$2"

  [[ "$id" == "win10"* ]] && desc="Windows 10"
  [[ "$id" == "win11"* ]] && desc="Windows 11"

  [ -z "$desc" ] && desc="Windows"

  echo "$desc for ${PLATFORM}"
  return 0
}

getName() {

  local file="$1"
  local desc="$2"

  [[ "${file,,}" == "win11"* ]] && desc="Windows 11"
  [[ "${file,,}" == "win10"* ]] && desc="Windows 10"
  [[ "${file,,}" == *"windows11"* ]] && desc="Windows 11"
  [[ "${file,,}" == *"windows10"* ]] && desc="Windows 10"
  [[ "${file,,}" == *"windows_11"* ]] && desc="Windows 11"
  [[ "${file,,}" == *"windows_10"* ]] && desc="Windows 10"

  if [ -z "$desc" ]; then
    desc="Windows"
  else
    if [[ "$desc" == "Windows 1"* ]] && [[ "${file,,}" == *"_iot_"* ]]; then
      desc="$desc IoT"
    else
      if [[ "$desc" == "Windows 1"* ]] && [[ "${file,,}" == *"_ltsc_"* ]]; then
        desc="$desc LTSC"
      fi
    fi
  fi

  echo "$desc for ${PLATFORM}"
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

secondLink() {

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

return 0
