#!/usr/bin/env bash
set -Eeuo pipefail

: "${MANUAL:=""}"
: "${DETECTED:=""}"
: "${VERSION:="win11arm64"}"

if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
  VERSION="${VERSION:1:-1}"
fi

[[ "${VERSION,,}" == "11" ]] && VERSION="win11arm64"
[[ "${VERSION,,}" == "win11" ]] && VERSION="win11arm64"

[[ "${VERSION,,}" == "10" ]] && VERSION="win10arm64"
[[ "${VERSION,,}" == "win10" ]] && VERSION="win10arm64"

CUSTOM=$(find "$STORAGE" -maxdepth 1 -type f -iname windows.iso -printf "%f\n" | head -n 1)
[ -z "$CUSTOM" ] && CUSTOM=$(find "$STORAGE" -maxdepth 1 -type f -iname custom.iso -printf "%f\n" | head -n 1)
[ -z "$CUSTOM" ] && CUSTOM=$(find "$STORAGE" -maxdepth 1 -type f -iname boot.iso -printf "%f\n" | head -n 1)
[ -z "$CUSTOM" ] && CUSTOM=$(find "$STORAGE" -maxdepth 1 -type f -iname custom.img -printf "%f\n" | head -n 1)

if [ -z "$CUSTOM" ] && [[ "${VERSION,,}" != "http"* ]]; then
  FN="${VERSION/\/storage\//}"
  [[ "$FN" == "."* ]] && FN="${FN:1}"
  CUSTOM=$(find "$STORAGE" -maxdepth 1 -type f -iname "$FN" -printf "%f\n" | head -n 1)
fi

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

  [[ "${name,,}" == *"windows 11"* ]] && detected="win11arm64"
  [[ "${name,,}" == *"windows 10"* ]] && detected="win10arm64"

  echo "$detected"
  return 0
}

hasDisk() {

  [ -b "${DEVICE:-}" ] && return 0

  if [ -s "$STORAGE/data.img" ] || [ -s "$STORAGE/data.qcow2" ]; then
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
  local aborted="$2"

  if [ ! -s "$iso" ] || [ ! -f "$iso" ]; then
    error "Failed to find ISO: $iso" && return 1
  fi

  if [ -w "$iso" ] && [[ "$aborted" != [Yy1]* ]]; then
    # Mark ISO as prepared via magic byte
    if ! printf '\x16' | dd of="$iso" bs=1 seek=0 count=1 conv=notrunc status=none; then
      error "Failed to set magic byte!" && return 1
    fi
  fi

  rm -f "$STORAGE/windows.boot"
  cp /run/version "$STORAGE/windows.ver"
  rm -f "$STORAGE/windows.old"

  rm -rf "$TMP"
  return 0
}

abortInstall() {

  local iso="$1"

  if [[ "$iso" != "$STORAGE/$BASE" ]]; then
    if ! mv -f "$iso" "$STORAGE/$BASE"; then
      error "Failed to move ISO: $iso" && return 1
    fi
  fi

  finishInstall "$STORAGE/$BASE" "Y" && return 0

  return 1
}

startInstall() {

  html "Starting Windows..."

  [ -z "$MANUAL" ] && MANUAL="N"

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
  fi

  if skipInstall; then
    [ ! -f "$STORAGE/$BASE" ] && BASE=""
    VGA="virtio-gpu"
    return 1
  fi

  if [ -f "$STORAGE/$BASE" ]; then

    # Check if the ISO was already processed by our script
    local magic=""
    magic=$(dd if="$STORAGE/$BASE" seek=0 bs=1 count=1 status=none | tr -d '\000')
    magic="$(printf '%s' "$magic" | od -A n -t x1 -v | tr -d ' \n')"

    if [[ "$magic" == "16" ]]; then

      if hasDisk || [[ "$MANUAL" == [Yy1]* ]]; then
        return 1
      fi

    fi

    EXTERNAL="Y"
    CUSTOM="$BASE"

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

  return 0
}

getESD() {

  local dir="$1"
  local file="$2"
  local architecture="ARM64"
  local winCatalog size

  case "${VERSION,,}" in
    win11arm64)
      winCatalog="https://go.microsoft.com/fwlink?linkid=2156292"
      ;;
    win10arm64)
      winCatalog="https://go.microsoft.com/fwlink/?LinkId=841361"
      ;;
    *)
      error "Invalid version specified: $VERSION" && return 1
      ;;
  esac

  local msg="Downloading product information from Microsoft..."
  info "$msg" && html "$msg"

  rm -rf "$dir"
  mkdir -p "$dir"

  local wFile="catalog.cab"

  { wget "$winCatalog" -O "$dir/$wFile" -q --no-check-certificate; rc=$?; } || :
  (( rc != 0 )) && error "Failed to download $winCatalog , reason: $rc" && return 1

  cd "$dir"

  if ! cabextract "$wFile" > /dev/null; then
    cd /run
    error "Failed to extract CAB file!" && return 1
  fi

  cd /run

  if [ ! -s "$dir/products.xml" ]; then
    error "Failed to find products.xml!" && return 1
  fi

  local esdLang="en-us"
  local editionName="Professional"
  local edQuery='//File[Architecture="'${architecture}'"][Edition="'${editionName}'"]'

  echo -e '<Catalog>' > "${dir}/products_filter.xml"
  xmllint --nonet --xpath "${edQuery}" "${dir}/products.xml" >> "${dir}/products_filter.xml" 2>/dev/null
  echo -e '</Catalog>'>> "${dir}/products_filter.xml"
  xmllint --nonet --xpath '//File[LanguageCode="'${esdLang}'"]' "${dir}/products_filter.xml" >"${dir}/esd_edition.xml"

  size=$(stat -c%s "${dir}/esd_edition.xml")
  if ((size<20)); then
    error "Failed to find Windows product!" && return 1
  fi

  ESD_URL=$(xmllint --nonet --xpath '//FilePath' "${dir}/esd_edition.xml" | sed -E -e 's/<[\/]?FilePath>//g')

  if [ -z "$ESD_URL" ]; then
    error "Failed to find ESD URL!" && return 1
  fi

  rm -rf "$dir"
  return 0
}

downloadImage() {

  local iso="$1"
  local url="$2"
  local desc rc progress

  rm -f "$iso"

  if [[ "$EXTERNAL" != [Yy1]* ]]; then

    desc=$(printVersion "$VERSION")
    [ -z "$desc" ] && desc="Windows"

  else

    desc=$(getName "$BASE")
    [ -z "$desc" ] && desc="$BASE"

  fi

  if [[ "$EXTERNAL" != [Yy1]* ]]; then

    if ! getESD "$TMP/esd" "$iso"; then
      return 1
    fi

    url="$ESD_URL"

  fi

  local msg="Downloading $desc..."
  info "$msg" && html "$msg"

  /run/progress.sh "$iso" "Downloading $desc ([P])..." &

  # Check if running with interactive TTY or redirected to docker log
  if [ -t 1 ]; then
    progress="--progress=bar:noscroll"
  else
    progress="--progress=dot:giga"
  fi

  { wget "$url" -O "$iso" -q --no-check-certificate --show-progress "$progress"; rc=$?; } || :

  fKill "progress.sh"
  (( rc != 0 )) && error "Failed to download $url , reason: $rc" && return 1

  if [ -f "$iso" ]; then
    if [ $(stat -c%s "$iso") -gt 100000000 ]; then
      html "Download finished successfully..." && return 0
    fi
  fi

  error "Failed to download $url" && return 1
}

extractESD() {

  local iso="$1"
  local dir="$2"
  local size size_gb space space_gb desc

  desc=$(printVersion "$VERSION")
  local msg="Extracting $desc bootdisk..."
  info "$msg" && html "$msg"

  if [ $(stat -c%s "$iso") -lt 100000000 ]; then
    error "Invalid ESD file: Size is smaller than 100 MB" && return 1
  fi

  rm -rf "$dir"
  mkdir -p "$dir"

  size=16106127360
  size_gb=$(( (size + 1073741823)/1073741824 ))
  space=$(df --output=avail -B 1 "$dir" | tail -n 1)
  space_gb=$(( (space + 1073741823)/1073741824 ))

  if (( size > space )); then
    error "Not enough free space in $STORAGE, have $space_gb GB available but need at least $size_gb GB." && return 1
  fi

  local esdImageCount
  esdImageCount=$(wimlib-imagex info "${iso}" | awk '/Image Count:/ {print $3}')

  wimlib-imagex apply "$iso" 1 "${dir}" --quiet 2>/dev/null || {
    retVal=$?
    error "Extracting bootdisk failed" && return $retVal
  }

  local bootWimFile="${dir}/sources/boot.wim"
  local installWimFile="${dir}/sources/install.wim"

  local msg="Extracting $desc environment..."
  info "$msg" && html "$msg"

  wimlib-imagex export "${iso}" 2 "${bootWimFile}" --compress=LZX --chunk-size 32K --quiet || {
    retVal=$?
    error "Adding WinPE failed" && return ${retVal}
  }

  local msg="Extracting $desc setup..."
  info "$msg" && html "$msg"

  wimlib-imagex export "${iso}" 3 "$bootWimFile" --compress=LZX --chunk-size 32K --boot --quiet || {
   retVal=$?
   error "Adding Windows Setup failed" && return ${retVal}
  }

  local msg="Extracting $desc image..."
  info "$msg" && html "$msg"

  local edition imageIndex imageEdition

  case "${VERSION,,}" in
    win11arm64)
      edition="11 pro"
      ;;
    win10arm64)
      edition="10 pro"
      ;;
    *)
      error "Invalid version specified: $VERSION" && return 1
      ;;
  esac

  for (( imageIndex=4; imageIndex<=esdImageCount; imageIndex++ )); do
    imageEdition=$(wimlib-imagex info "${iso}" ${imageIndex} | grep '^Description:' | sed 's/Description:[ \t]*//')
    [[ "${imageEdition,,}" != *"$edition"* ]] && continue
    wimlib-imagex export "${iso}" ${imageIndex} "${installWimFile}" --compress=LZMS --chunk-size 128K --quiet || {
      retVal=$?
      error "Addition of ${imageIndex} to the image failed" && return $retVal
    }
    return 0
  done

  error "Failed to find product in install.wim!" && return 1
}

extractImage() {

  local iso="$1"
  local dir="$2"
  local desc="downloaded ISO"
  local size size_gb space space_gb

  if [[ "${iso,,}" == *".esd" ]]; then
    return extractESD "$iso" "$dir"
  fi

  if [[ "$EXTERNAL" != [Yy1]* ]] && [ -z "$CUSTOM" ]; then
    desc=$(printVersion "$VERSION")
    [ -z "$desc" ] && desc="downloaded ISO"
  fi

  local msg="Extracting $desc image..."
  [ -n "$CUSTOM" ] && msg="Extracting local ISO image..."
  info "$msg" && html "$msg"

  rm -rf "$dir"
  mkdir -p "$dir"

  size=$(stat -c%s "$iso")
  size_gb=$(( (size + 1073741823)/1073741824 ))
  space=$(df --output=avail -B 1 "$dir" | tail -n 1)
  space_gb=$(( (space + 1073741823)/1073741824 ))

  if ((size<100000000)); then
    error "Invalid ISO file: Size is smaller than 100 MB" && return 1
  fi

  if (( size > space )); then
    error "Not enough free space in $STORAGE, have $space_gb GB available but need at least $size_gb GB." && return 1
  fi

  rm -rf "$dir"

  if ! 7z x "$iso" -o"$dir" > /dev/null; then
    error "Failed to extract ISO file: $iso" && return 1
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

  local src loc tag result name name2 desc
  src=$(find "$dir" -maxdepth 1 -type d -iname sources | head -n 1)

  if [ ! -d "$src" ]; then
    warn "failed to locate 'sources' folder in ISO image, $FB" && return 1
  fi

  loc=$(find "$src" -maxdepth 1 -type f -iname install.wim | head -n 1)
  [ ! -f "$loc" ] && loc=$(find "$src" -maxdepth 1 -type f -iname install.esd | head -n 1)

  if [ ! -f "$loc" ]; then
    warn "failed to locate 'install.wim' or 'install.esd' in ISO image, $FB" && return 1
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
    warn "failed to determine Windows version from string '$name', $FB" && return 0
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
  local path src loc index result

  [ ! -s "$asset" ] || [ ! -f "$asset" ] && return 0

  path=$(find "$dir" -maxdepth 1 -type f -iname autounattend.xml | head -n 1)
  [ -n "$path" ] && cp "$asset" "$path"

  src=$(find "$dir" -maxdepth 1 -type d -iname sources | head -n 1)

  if [ ! -d "$src" ]; then
    warn "failed to locate 'sources' folder in ISO image, $FB" && return 1
  fi

  loc=$(find "$src" -maxdepth 1 -type f -iname boot.wim | head -n 1)
  [ ! -f "$loc" ] && loc=$(find "$src" -maxdepth 1 -type f -iname boot.esd | head -n 1)

  if [ ! -f "$loc" ]; then
    warn "failed to locate 'boot.wim' or 'boot.esd' in ISO image, $FB" && return 1
  fi

  info "Adding XML file for automatic installation..."

  index="1"
  result=$(wimlib-imagex info -xml "$loc" | tr -d '\000')

  if [[ "${result^^}" == *"<IMAGE INDEX=\"2\">"* ]]; then
    index="2"
  fi

  if ! wimlib-imagex update "$loc" "$index" --command "add $asset /autounattend.xml" > /dev/null; then
    warn "failed to add XML to ISO image, $FB" && return 1
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
    error "Not enough free space in $STORAGE, have $space_gb GB available but need at least $size_gb GB." && return 1
  fi

  if ! genisoimage -o "$out" -b "$ETFS" -no-emul-boot -c "$cat" -iso-level 4 -J -l -D -N -joliet-long -relaxed-filenames -V "$label" \
                    -udf -boot-info-table -eltorito-alt-boot -eltorito-boot "$EFISYS" -no-emul-boot -allow-limited-size -quiet "$dir" 2> "$log"; then
    [ -s "$log" ] && echo "$(<"$log")"
    error "Failed to build image!" && return 1
  fi

  local error=""
  local hide="Warning: creating filesystem that does not conform to ISO-9660."

  [ -s "$log" ] && error="$(<"$log")"
  [[ "$error" != "$hide" ]] && echo "$error"

  if [ -f "$STORAGE/$BASE" ]; then
    error "File $STORAGE/$BASE does already exist?!" && return 1
  fi

  mv "$out" "$STORAGE/$BASE"
  return 0
}

bootWindows() {

  if [ -s "$STORAGE/windows.mode" ] && [ -f "$STORAGE/windows.mode" ]; then
    BOOT_MODE=$(<"$STORAGE/windows.mode")
    rm -rf "$TMP"
    return 0
  fi

  rm -rf "$TMP"
  return 0
}

######################################

if ! startInstall; then
  bootWindows && return 0
  exit 68
fi

if [ ! -s "$ISO" ] || [ ! -f "$ISO" ]; then
  if ! downloadImage "$ISO" "$VERSION"; then
    rm -f "$ISO"
    exit 61
  fi
fi

if ! extractImage "$ISO" "$DIR"; then
  rm -f "$ISO"
  exit 62
fi

if ! detectImage "$DIR"; then
  abortInstall "$ISO" && return 0
  exit 60
fi

if ! prepareImage "$ISO" "$DIR"; then
  abortInstall "$ISO" && return 0
  exit 60
fi

if ! updateImage "$ISO" "$DIR" "$XML"; then
  abortInstall "$ISO" && return 0
  exit 60
fi

if ! rm -f "$ISO" 2> /dev/null; then
  BASE="windows.iso"
  ISO="$STORAGE/$BASE"
  rm -f  "$ISO"
fi

if ! buildImage "$DIR"; then
  exit 65
fi

if ! finishInstall "$STORAGE/$BASE" "N"; then
  exit 69
fi

html "Successfully prepared image for installation..."
return 0
