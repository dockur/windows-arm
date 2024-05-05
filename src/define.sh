#!/usr/bin/env bash
set -Eeuo pipefail

: "${VERIFY:=""}"
: "${MANUAL:=""}"
: "${REMOVE:=""}"
: "${VERSION:=""}"
: "${DETECTED:=""}"
: "${PLATFORM:="ARM64"}"

MIRRORS=2

parseVersion() {

  VERSION="${VERSION/\//}"

  if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
    VERSION="${VERSION:1:-1}"
  fi

  [ -z "$VERSION" ] && VERSION="win11"

  case "${VERSION,,}" in
    "11" | "11p" | "win11" | "win11p" | "windows11" | "windows 11" )
      VERSION="win11${PLATFORM,,}"
      ;;
    "10" | "10p" | "win10" | "win10p" | "windows10" | "windows 10" )
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

getCatalog() {

  local id="$1"
  local ret="$2"
  local url=""
  local name=""
  local edition=""

  case "${id,,}" in
    "win11${PLATFORM,,}" )
      edition="Professional"
      name="Windows 11 Pro"
      url="https://go.microsoft.com/fwlink?linkid=2156292"
      ;;
    "win10${PLATFORM,,}" )
      edition="Professional"
      name="Windows 10 Pro"
      url="https://go.microsoft.com/fwlink/?LinkId=841361"
      ;;
  esac

  case "${ret,,}" in
    "url" ) echo "$url" ;;
    "name" ) echo "$name" ;;
    "edition" ) echo "$edition" ;;
    *) echo "";;
  esac

  return 0
}

getLink1() {

  # Fallbacks for users who cannot connect to the Microsoft servers

  local id="$1"
  local ret="$2"
  local url=""
  local sum=""
  local size=""
  local host="https://dl.bobpony.com/windows"

  case "${id,,}" in
    "win11${PLATFORM,,}")
      size=5946128384
      sum="0c8edeae3202cf6f4bf8bb65c9f6176374c48fdcbcc8d0effa8547be75e9fd20"
      url="$host/11/en-us_windows_11_23h2_${PLATFORM,,}.iso"
      ;;
    "win10${PLATFORM,,}")
      size=4957009920
      sum="64461471292b79d18cd9cced6cc141d7773b489a9b3e12de7b120312e63bfaf1"
      url="$host/10/en-us_windows_10_22h2_${PLATFORM,,}.iso"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    *) echo "$url";;
  esac

  return 0
}

getLink2() {

  # Fallbacks for users who cannot connect to the Microsoft servers

  local id="$1"
  local ret="$2"
  local url=""
  local sum=""
  local size=""
  local host="https://drive.massgrave.dev"

  case "${id,,}" in
    "win11${PLATFORM,,}")
      size=7010680832
      sum="3da19e8c8c418091081186e362fb53a1aa68dad255d1d28ace81e2c88c3f99ba"
      url="$host/SW_DVD9_Win_Pro_11_23H2.2_Arm64_English_Pro_Ent_EDU_N_MLF_X23-68023.ISO"
      ;;
    "win10${PLATFORM,,}")
      size=5190453248
      sum="bd96b342193f81c0a2e6595d8d8b8dc01dbf789d19211699f6299fec7b712197"
      url="$host/SW_DVD9_Win_Pro_10_22H2.15_Arm64_English_Pro_Ent_EDU_N_MLF_X23-67223.ISO"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    *) echo "$url";;
  esac

  return 0
}

getValue() {

  local val=""
  local id="$3"
  local type="$2"
  local func="getLink$1"

  if [ "$1" -gt 0 ] && [ "$1" -le "$MIRRORS" ]; then
    val=$($func "$id" "$type")
  fi

  echo "$val"
  return 0
}

getLink() {

  local url=""
  url=$(getValue "$1" "" "$2")

  echo "$url"
  return 0
}

getHash() {

  local sum=""
  sum=$(getValue "$1" "sum" "$2")

  echo "$sum"
  return 0
}

getSize() {

  local size=""
  size=$(getValue "$1" "size" "$2")

  echo "$size"
  return 0
}

isMido() {
  return 1
}

isESD() {

  local id="$1"
  local url

  url=$(getCatalog "$id" "url")
  [ -n "$url" ] && return 0

  return 1
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

migrateFiles() {
  return 0
}

return 0
