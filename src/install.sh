#!/usr/bin/env bash
set -Eeuo pipefail

: "${MANUAL:=""}"
: "${DETECTED:=""}"
: "${VERSION:="win11arm"}"

if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
  VERSION="${VERSION:1:-1}"
fi

[[ "${VERSION,,}" == "11" ]] && VERSION="win11arm"
[[ "${VERSION,,}" == "win11" ]] && VERSION="win11arm"

[[ "${VERSION,,}" == "10" ]] && VERSION="win10arm"
[[ "${VERSION,,}" == "win10" ]] && VERSION="win10arm"

CUSTOM="custom.iso"

[ ! -f "$STORAGE/$CUSTOM" ] && CUSTOM="Custom.iso"
[ ! -f "$STORAGE/$CUSTOM" ] && CUSTOM="custom.ISO"
[ ! -f "$STORAGE/$CUSTOM" ] && CUSTOM="CUSTOM.ISO"
[ ! -f "$STORAGE/$CUSTOM" ] && CUSTOM="custom.img"
[ ! -f "$STORAGE/$CUSTOM" ] && CUSTOM="Custom.img"
[ ! -f "$STORAGE/$CUSTOM" ] && CUSTOM="custom.IMG"
[ ! -f "$STORAGE/$CUSTOM" ] && CUSTOM="CUSTOM.IMG"

ESD_URL=""
TMP="$STORAGE/tmp"
DIR="$TMP/unpack"
FB="falling back to manual installation!"
ETFS="boot/etfsboot.com"
EFISYS="efi/microsoft/boot/efisys_noprompt.bin"

printVersion() {

  local id="$1"
  local desc=""

  [[ "$id" == "win10"* ]] && desc="Windows 10 for ARM"
  [[ "$id" == "win11"* ]] && desc="Windows 11 for ARM"

  echo "$desc"
  return 0
}

getName() {

  local file="$1"
  local desc=""

  [[ "${file,,}" == "win11"* ]] && desc="Windows 11 for ARM"
  [[ "${file,,}" == "win10"* ]] && desc="Windows 10 for ARM"
  [[ "${file,,}" == *"windows11"* ]] && desc="Windows 11 for ARM"
  [[ "${file,,}" == *"windows10"* ]] && desc="Windows 10 for ARM"
  [[ "${file,,}" == *"windows_11"* ]] && desc="Windows 11 for ARM"
  [[ "${file,,}" == *"windows_10"* ]] && desc="Windows 10 for ARM"

  echo "$desc"
  return 0
}

getVersion() {

  local name="$1"
  local detected=""

  [[ "${name,,}" == *"windows 11"* ]] && detected="win11arm"
  [[ "${name,,}" == *"windows 10"* ]] && detected="win10arm"

  echo "$detected"
  return 0
}

replaceXML() {

  local dir="$1"
  local asset="$2"

  local path="$dir/autounattend.xml"
  [ -f "$path" ] && cp "$asset" "$path"
  path="$dir/Autounattend.xml"
  [ -f "$path" ] && cp "$asset" "$path"
  path="$dir/AutoUnattend.xml"
  [ -f "$path" ] && cp "$asset" "$path"
  path="$dir/autounattend.XML"
  [ -f "$path" ] && cp "$asset" "$path"
  path="$dir/Autounattend.XML"
  [ -f "$path" ] && cp "$asset" "$path"
  path="$dir/AutoUnattend.XML"
  [ -f "$path" ] && cp "$asset" "$path"
  path="$dir/AUTOUNATTEND.xml"
  [ -f "$path" ] && cp "$asset" "$path"
  path="$dir/AUTOUNATTEND.XML"
  [ -f "$path" ] && cp "$asset" "$path"

  return 0
}

hasDisk() {

  [ -b "${DEVICE:-}" ] && return 0

  if [ -f "$STORAGE/data.img" ] || [ -f "$STORAGE/data.qcow2" ]; then
    return 0
  fi

  return 1
}

skipInstall() {

  if hasDisk && [ -f "$STORAGE/windows.boot" ]; then
    return 0
  fi

  return 1
}

finishInstall() {

  local iso="$1"

  # Mark ISO as prepared via magic byte
  printf '\x16' | dd of="$iso" bs=1 seek=0 count=1 conv=notrunc status=none

  rm -f "$STORAGE/windows.boot"
  cp /run/version "$STORAGE/windows.ver"
  rm -f "$STORAGE/windows.old"

  rm -rf "$TMP"
  return 0
}

abortInstall() {

  local iso="$1"

  if [[ "$iso" != "$STORAGE/$BASE" ]]; then
    mv -f "$iso" "$STORAGE/$BASE"
  fi

  finishInstall "$STORAGE/$BASE"
  return 0
}

startInstall() {

  html "Starting Windows..."

  if [ -f "$STORAGE/$CUSTOM" ]; then

    EXTERNAL="Y"
    BASE="$CUSTOM"

  else

    CUSTOM=""

    if [[ "${VERSION,,}" == "http"* ]]; then
      EXTERNAL="Y"
    else
      EXTERNAL="N"
    fi

    if [[ "$EXTERNAL" != [Yy1]* ]]; then

      BASE="$VERSION.iso"

    else

      BASE=$(basename "${VERSION%%\?*}")
      : "${BASE//+/ }"; printf -v BASE '%b' "${_//%/\\x}"
      BASE=$(echo "$BASE" | sed -e 's/[^A-Za-z0-9._-]/_/g')

    fi

    [[ "${BASE,,}" == "custom."* ]] && BASE="windows.iso"

  fi

  [ -z "$MANUAL" ] && MANUAL="N"

  if [ -f "$STORAGE/$BASE" ]; then

    # Check if the ISO was already processed by our script
    local magic=""
    magic=$(dd if="$STORAGE/$BASE" seek=0 bs=1 count=1 status=none | tr -d '\000')
    magic="$(printf '%s' "$magic" | od -A n -t x1 -v | tr -d ' \n')"

    if [[ "$magic" == "16" ]]; then

      if hasDisk || [[ "$MANUAL" = [Yy1]* ]]; then
        return 1
      fi

    fi

    EXTERNAL="Y"
    CUSTOM="$BASE"

  else

    if skipInstall; then
      BASE=""
      return 1
    fi

  fi

  rm -rf "$TMP"
  mkdir -p "$TMP"

  if [ ! -f "$STORAGE/$CUSTOM" ]; then
    CUSTOM=""
    if [[ "$EXTERNAL" == [Yy1]* ]]; then
      ISO="$TMP/$BASE"
    else
      ISO="$TMP/$VERSION.esd"
    fi
  else
    ISO="$STORAGE/$CUSTOM"
  fi

  rm -f "$TMP/$BASE"
  return 0
}

getESD() {

  local dir="$1"
  local file="$2"
  local architecture="ARM64"
  local winCatalog space space_gb size

  case "${VERSION,,}" in
    win11arm)
      winCatalog="https://go.microsoft.com/fwlink?linkid=2156292"
      ;;
    win10arm)
      winCatalog="https://go.microsoft.com/fwlink/?LinkId=841361"
      ;;
    *)
      error "Invalid version specified: $VERSION"
      return 1
      ;;
  esac

  local msg="Downloading product information from Microsoft..."
  info "$msg" && html "$msg"

  rm -rf "$dir"
  mkdir -p "$dir"
  rm -f "$file"

  space=$(df --output=avail -B 1 "$dir" | tail -n 1)
  space_gb=$(( (space + 1073741823)/1073741824 ))

  if (( 12884901888 > space )); then
    error "Not enough free space in $STORAGE, have $space_gb GB available but need at least 12 GB."
    return 1
  fi

  local wFile="catalog.cab"

  mkdir -p "$dir"

  { wget "$winCatalog" -O "$dir/$wFile" -q --no-check-certificate; rc=$?; } || :
  (( rc != 0 )) && error "Failed to download $winCatalog , reason: $rc" && return 1

  cd "$dir"

  if ! cabextract "$wFile" > /dev/null; then
    cd /run
    error "Failed to extract CAB file!" && return 1
  fi

  cd /run

  if [ ! -f "$dir/products.xml" ]; then
    error "Failed to find products.xml!" && return 1
  fi

  local esdLang="en-us"
  local editionName="Professional"
  local edQuery='//File[Architecture="'${architecture}'"][Edition="'${editionName}'"]'

  echo -e '<Catalog>' > "${dir}/products_filter.xml"
  xpath -q -n -e "${edQuery}" "${dir}/products.xml" >> "${dir}/products_filter.xml" 2>/dev/null
  echo -e '</Catalog>'>> "${dir}/products_filter.xml"
  xpath -q -n -e '//File[LanguageCode="'${esdLang}'"]' "${dir}/products_filter.xml" >"${dir}/esd_edition.xml"

  size=$(stat -c%s "${dir}/esd_edition.xml")
  if ((size<20)); then
    error "Invalid esd_edition.xml file!" && return 1
  fi

  ESD_URL=$(xpath -n -q -e '//FilePath' "${dir}/esd_edition.xml" | sed -E -e 's/<[\/]?FilePath>//g')

  if [ -z "$ESD_URL" ]; then
    error "Failed to find ESD url!" && return 1
  fi

  rm -rf "$dir"
  return 0
}

downloadImage() {

  local iso="$1"
  local url="$2"
  local file="$iso"
  local desc rc progress

  rm -f "$iso"

  if [[ "$EXTERNAL" != [Yy1]* ]]; then

    file="$iso"
    desc=$(printVersion "$VERSION")
    [ -z "$desc" ] && desc="Windows"

  else

    desc=$(getName "$BASE")
    [ -z "$desc" ] && desc="$BASE"

  fi

  if [[ "$EXTERNAL" != [Yy1]* ]]; then

    if ! getESD "$TMP/esd" "$file"; then
      return 1
    fi

    url="$ESD_URL"

  fi

  local msg="Downloading $desc..."
  info "$msg" && html "$msg"

  /run/progress.sh "$file" "Downloading $desc ([P])..." &

  # Check if running with interactive TTY or redirected to docker log
  if [ -t 1 ]; then
    progress="--progress=bar:noscroll"
  else
    progress="--progress=dot:giga"
  fi

  { wget "$url" -O "$iso" -q --no-check-certificate --show-progress "$progress"; rc=$?; } || :

  fKill "progress.sh"
  (( rc != 0 )) && error "Failed to download $url , reason: $rc" && exit 60

  [ ! -f "$iso" ] && return 1

  html "Download finished successfully..."
  return 0
}

extractESD() {

  local iso="$1"
  local dir="$2"
  local size desc

  desc=$(printVersion "$VERSION")
  local msg="Extracting $desc bootdisk..."
  info "$msg" && html "$msg"

  size=$(stat -c%s "$iso")

  if ((size<10000000)); then
    error "Invalid ESD file: Size is smaller than 10 MB" && exit 62
  fi

  rm -rf "$dir"
  mkdir -p "$dir"

  local esdImageCount
  esdImageCount=$(wimlib-imagex info "${iso}" | awk '/Image Count:/ {print $3}')

  wimlib-imagex apply "$iso" 1 "${dir}" --quiet 2>/dev/null || {
    retVal=$?
    error "Extract of boot files failed" && return $retVal
  }

  local bootWimFile="${dir}/sources/boot.wim"
  local installWimFile="${dir}/sources/install.wim"

  local msg="Extracting $desc environment..."
  info "$msg" && html "$msg"

  wimlib-imagex export "${iso}" 2 "${bootWimFile}" --compress=LZX --chunk-size 32K --quiet || {
    retVal=$?
    error "Add of WinPE failed" && return ${retVal}
  }

  local msg="Extracting $desc setup..."
  info "$msg" && html "$msg"

  wimlib-imagex export "${iso}" 3 "$bootWimFile" --compress=LZX --chunk-size 32K --boot --quiet || {
   retVal=$?
   error "Add of Windows Setup failed" && return ${retVal}
  }

  local msg="Extracting $desc image..."
  info "$msg" && html "$msg"

  local edition imageIndex imageEdition

  case "${VERSION,,}" in
    win11arm)
      edition="11 pro"
      ;;
    win10arm)
      edition="10 pro"
      ;;
    *)
      error "Invalid version specified: $VERSION"
      return 1
      ;;
  esac
  
  for (( imageIndex=4; imageIndex<=esdImageCount; imageIndex++ )); do
    imageEdition=$(wimlib-imagex info "${iso}" ${imageIndex} | grep '^Description:' | sed 's/Description:[ \t]*//')
    [[ "${imageEdition,,}" != *"$edition"* ]] && continue
    wimlib-imagex export "${iso}" ${imageIndex} "${installWimFile}" --compress=LZMS --chunk-size 128K --quiet || {
      retVal=$?
      error "Addition of ${imageIndex} to the image failed" && return $retVal
    }
    break
  done

  return 0
}

extractImage() {

  local iso="$1"
  local dir="$2"
  local desc="downloaded ISO"
  local size size_gb space space_gb

  if [[ "${iso,,}" == *".esd" ]]; then
    if ! extractESD "$iso" "$dir"; then
      error "Failed to extract ESD file!"
      exit 67
    fi
    return 0
  fi

  if [[ "$EXTERNAL" != [Yy1]* ]] && [ -z "$CUSTOM" ]; then
    desc=$(printVersion "$VERSION")
    [ -z "$desc" ] && desc="downloaded ISO"
  fi

  local msg="Extracting $desc image..."
  [ -n "$CUSTOM" ] && msg="Extracting local ISO image..."
  info "$msg" && html "$msg"

  size=$(stat -c%s "$iso")
  size_gb=$(( (size + 1073741823)/1073741824 ))
  space=$(df --output=avail -B 1 "$TMP" | tail -n 1)
  space_gb=$(( (space + 1073741823)/1073741824 ))

  if ((size<10000000)); then
    error "Invalid ISO file: Size is smaller than 10 MB" && exit 62
  fi

  if (( size > space )); then
    error "Not enough free space in $STORAGE, have $space_gb GB available but need at least $size_gb GB." && exit 63
  fi

  rm -rf "$dir"

  if ! 7z x "$iso" -o"$dir" > /dev/null; then
    error "Failed to extract ISO file!"
    exit 66
  fi

  return 0
}

detectImage() {

  XML=""
  local dir="$1"

  if [ -n "$CUSTOM" ]; then
    DETECTED=""
  else
    if [ -z "$DETECTED" ] && [[ "$EXTERNAL" != [Yy1]* ]]; then
      DETECTED="$VERSION"
    fi
  fi

  if [ -n "$DETECTED" ]; then

    if [ -f "/run/assets/$DETECTED.xml" ]; then
      [[ "$MANUAL" != [Yy1]* ]] && XML="$DETECTED.xml"
      return 0
    fi

    if [[ "${DETECTED,,}" != "winxp"* ]]; then

      local dsc
      dsc=$(printVersion "$DETECTED")
      [ -z "$dsc" ] && dsc="$DETECTED"

      warn "got $dsc, but no matching XML file exists, $FB."
    fi

    return 0
  fi

  info "Detecting Windows version from ISO image..."

  local tag result name name2 desc
  local loc="$dir/sources/install.wim"
  [ ! -f "$loc" ] && loc="$dir/sources/install.esd"

  if [ ! -f "$loc" ]; then
    warn "failed to locate 'install.wim' or 'install.esd' in ISO image, $FB"
    return 0
  fi

  tag="DISPLAYNAME"
  result=$(wimlib-imagex info -xml "$loc" | tr -d '\000')
  name=$(sed -n "/$tag/{s/.*<$tag>\(.*\)<\/$tag>.*/\1/;p}" <<< "$result")
  DETECTED=$(getVersion "$name")

  if [ -z "$DETECTED" ]; then

    tag="PRODUCTNAME"
    name2=$(sed -n "/$tag/{s/.*<$tag>\(.*\)<\/$tag>.*/\1/;p}" <<< "$result")
    [ -z "$name" ] && name="$name2"
    DETECTED=$(getVersion "$name2")

  fi

  if [ -z "$DETECTED" ]; then
    warn "failed to determine Windows version from string '$name', $FB"
    return 0
  fi

  desc=$(printVersion "$DETECTED")
  [ -z "$desc" ] && desc="$DETECTED"

  if [ -f "/run/assets/$DETECTED.xml" ]; then
    [[ "$MANUAL" != [Yy1]* ]] && XML="$DETECTED.xml"
    info "Detected: $desc"
  else
    warn "detected $desc, but no matching XML file exists, $FB."
  fi

  return 0
}

prepareImage() {

  local iso="$1"
  local dir="$2"

  if [ -f "$dir/$ETFS" ] && [ -f "$dir/$EFISYS" ]; then
    return 0
  fi

  if [ ! -f "$dir/$ETFS" ]; then
    warn "failed to locate file 'etfsboot.com' in ISO image!"
  else
    warn "failed to locate file 'efisys_noprompt.bin' in ISO image!"
  fi

  return 1
}

updateImage() {

  local iso="$1"
  local dir="$2"
  local asset="/run/assets/$3"
  local index result

  [ ! -f "$asset" ] && return 0
  replaceXML "$dir" "$asset"

  local loc="$dir/sources/boot.wim"
  [ ! -f "$loc" ] && loc="$dir/sources/boot.esd"

  if [ ! -f "$loc" ]; then
    warn "failed to locate 'boot.wim' or 'boot.esd' in ISO image, $FB"
    return 1
  fi

  info "Adding XML file for automatic installation..."

  index="1"
  result=$(wimlib-imagex info -xml "$loc" | tr -d '\000')

  if [[ "${result^^}" == *"<IMAGE INDEX=\"2\">"* ]]; then
    index="2"
  fi

  if ! wimlib-imagex update "$loc" "$index" --command "add $asset /autounattend.xml" > /dev/null; then
    warn "failed to add XML to ISO image, $FB"
    return 1
  fi

  return 0
}

buildImage() {

  local dir="$1"
  local cat="BOOT.CAT"
  local label="${BASE%.*}"
  local log="/run/shm/iso.log"
  local size size_gb space space_gb desc

  label="${label::30}"
  local out="$TMP/$label.tmp"
  rm -f "$out"

  desc=$(printVersion "$DETECTED")
  [ -z "$desc" ] && desc="ISO"

  local msg="Building $desc image..."
  info "$msg" && html "$msg"

  size=$(du -h -b --max-depth=0 "$dir" | cut -f1)
  size_gb=$(( (size + 1073741823)/1073741824 ))
  space=$(df --output=avail -B 1 "$TMP" | tail -n 1)
  space_gb=$(( (space + 1073741823)/1073741824 ))

  if (( size > space )); then
    error "Not enough free space in $STORAGE, have $space_gb GB available but need at least $size_gb GB."
    return 1
  fi

  if ! genisoimage -o "$out" -b "$ETFS" -no-emul-boot -c "$cat" -iso-level 4 -J -l -D -N -joliet-long -relaxed-filenames -V "$label" \
                    -udf -boot-info-table -eltorito-alt-boot -eltorito-boot "$EFISYS" -no-emul-boot -allow-limited-size -quiet "$dir" 2> "$log"; then
    [ -f "$log" ] && echo "$(<"$log")"
    return 1
  fi

  local error=""
  local hide="Warning: creating filesystem that does not conform to ISO-9660."

  [ -f "$log" ] && error="$(<"$log")"
  [[ "$error" != "$hide" ]] && echo "$error"

  if [ -f "$STORAGE/$BASE" ]; then
    error "File $STORAGE/$BASE does already exist?!"
    return 1
  fi

  mv "$out" "$STORAGE/$BASE"
  return 0
}

######################################

if ! startInstall; then
  rm -rf "$TMP"
  return 0
fi

if [ ! -f "$ISO" ]; then
  if ! downloadImage "$ISO" "$VERSION"; then
    error "Failed to download $VERSION"
    exit 61
  fi
fi

if ! extractImage "$ISO" "$DIR"; then
  abortInstall "$ISO"
  return 0
fi

if ! detectImage "$DIR"; then
  abortInstall "$ISO"
  return 0
fi

if ! prepareImage "$ISO" "$DIR"; then
  abortInstall "$ISO"
  return 0
fi

if ! updateImage "$ISO" "$DIR" "$XML"; then
  abortInstall "$ISO"
  return 0
fi

rm -f "$ISO"

if ! buildImage "$DIR"; then
  error "Failed to build image!"
  exit 65
fi

finishInstall "$STORAGE/$BASE"

html "Successfully prepared image for installation..."
return 0
