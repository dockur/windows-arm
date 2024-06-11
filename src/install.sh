#!/usr/bin/env bash
set -Eeuo pipefail

TMP="$STORAGE/tmp"
DIR="$TMP/unpack"
FB="falling back to manual installation!"
ETFS="boot/etfsboot.com"
EFISYS="efi/microsoft/boot/efisys_noprompt.bin"

skipInstall() {

  local iso="$1"
  local magic byte
  local boot="$STORAGE/windows.boot"
  local previous="$STORAGE/windows.base"

  if [ -f "$previous" ]; then
    previous=$(<"$previous")
    if [ -n "$previous" ]; then
      previous="$STORAGE/$previous"
      if [[ "${previous,,}" != "${iso,,}" ]]; then
        if [ -f "$boot" ] && hasDisk; then
          info "Detected that the version was changed, but ignoring this because Windows is already installed."
          info "Please start with an empty /storage folder, if you want to install a different version of Windows."
          return 0
        fi
        [ -f "$previous" ] && rm -f "$previous"
        return 1
      fi
    fi
  fi

  [ -f "$boot" ] && hasDisk && return 0

  [ ! -f "$iso" ] && return 1
  [ ! -s "$iso" ] && return 1

  # Check if the ISO was already processed by our script
  magic=$(dd if="$iso" seek=0 bs=1 count=1 status=none | tr -d '\000')
  magic="$(printf '%s' "$magic" | od -A n -t x1 -v | tr -d ' \n')"
  byte="16" && [[ "$MANUAL" == [Yy1]* ]] && byte="17"

  if [[ "$magic" != "$byte" ]]; then
    info "The ISO will be processed again because the configuration was changed..."
    return 1
  fi

  return 0
}

startInstall() {

  html "Starting $APP..."

  if [ -z "$CUSTOM" ]; then

    local file="${VERSION//\//}.iso"

    if [[ "${VERSION,,}" == "http"* ]]; then

      file=$(basename "${VERSION%%\?*}")
      : "${file//+/ }"; printf -v file '%b' "${_//%/\\x}"
      file=$(echo "$file" | sed -e 's/[^A-Za-z0-9._-]/_/g')

    else

      local language
      language=$(getLanguage "$LANGUAGE" "culture")
      language="${language%%-*}"

      if [ -n "$language" ] && [[ "${language,,}" != "en" ]]; then
        file="${VERSION//\//}_${language,,}.iso"
      fi

    fi

    BOOT="$STORAGE/$file"

    ! migrateFiles "$BOOT" "$VERSION" && error "Migration failed!" && exit 57

  fi

  skipInstall "$BOOT" && return 1

  rm -rf "$TMP"
  mkdir -p "$TMP"

  if [ -z "$CUSTOM" ]; then

    ISO=$(basename "$BOOT")
    ISO="$TMP/$ISO"

    if [ -f "$BOOT" ] && [ -s "$BOOT" ]; then
      mv -f "$BOOT" "$ISO"
    fi

  fi

  rm -f "$BOOT"
  return 0
}

finishInstall() {

  local iso="$1"
  local aborted="$2"
  local base byte

  if [ ! -s "$iso" ] || [ ! -f "$iso" ]; then
    error "Failed to find ISO file: $iso" && return 1
  fi

  if [[ "$aborted" != [Yy1]* ]]; then
    # Mark ISO as prepared via magic byte
    byte="16" && [[ "$MANUAL" == [Yy1]* ]] && byte="17"
    if ! printf '%b' "\x$byte" | dd of="$iso" bs=1 seek=0 count=1 conv=notrunc status=none; then
      warn "failed to set magic byte in ISO file: $iso"
    fi
  fi

  rm -f "$STORAGE/windows.old"
  rm -f "$STORAGE/windows.vga"
  rm -f "$STORAGE/windows.base"
  rm -f "$STORAGE/windows.boot"
  rm -f "$STORAGE/windows.mode"
  rm -f "$STORAGE/windows.type"

  cp -f /run/version "$STORAGE/windows.ver"

  if [[ "$iso" == "$STORAGE/"* ]]; then
    if [[ "$aborted" != [Yy1]* ]] || [ -z "$CUSTOM" ]; then
      base=$(basename "$iso")
      echo "$base" > "$STORAGE/windows.base"
    fi
  fi

  if [[ "${PLATFORM,,}" == "x64" ]]; then
    if [[ "${BOOT_MODE,,}" == "windows_legacy" ]]; then
      echo "$BOOT_MODE" > "$STORAGE/windows.mode"
      if [[ "${MACHINE,,}" != "q35" ]]; then
        echo "$MACHINE" > "$STORAGE/windows.old"
      fi
    else
      # Enable secure boot + TPM on manual installs as Win11 requires
      if [[ "$MANUAL" == [Yy1]* ]] || [[ "$aborted" == [Yy1]* ]]; then
        if [[ "${DETECTED,,}" == "win11"* ]]; then
          BOOT_MODE="windows_secure"
          echo "$BOOT_MODE" > "$STORAGE/windows.mode"
        fi
      fi
      # Enable secure boot on multi-socket systems to workaround freeze
      if [ -n "$SOCKETS" ] && [[ "$SOCKETS" != "1" ]]; then
        BOOT_MODE="windows_secure"
        echo "$BOOT_MODE" > "$STORAGE/windows.mode"
      fi
    fi
  fi

  if [ -n "${VGA:-}" ] && [[ "${VGA:-}" != "virtio" ]] && [[ "${VGA:-}" != "ramfb" ]]; then
    echo "$VGA" > "$STORAGE/windows.vga"
  fi

  if [ -n "${DISK_TYPE:-}" ] && [[ "${DISK_TYPE:-}" != "scsi" ]]; then
    echo "$DISK_TYPE" > "$STORAGE/windows.type"
  fi

  rm -rf "$TMP"
  return 0
}

abortInstall() {

  local dir="$1"
  local iso="$2"
  local efi

  [[ "${iso,,}" == *".esd" ]] && exit 60

  efi=$(find "$dir" -maxdepth 1 -type d -iname efi | head -n 1)

  if [ -z "$efi" ]; then
    [[ "${PLATFORM,,}" == "x64" ]] && BOOT_MODE="windows_legacy"
  fi

  if [ -n "$CUSTOM" ]; then
    BOOT="$iso"
    REMOVE="N"
  else
    if [[ "$iso" != "$BOOT" ]]; then
      if ! mv -f "$iso" "$BOOT"; then
        error "Failed to move ISO file: $iso" && return 1
      fi
    fi
  fi

  finishInstall "$BOOT" "Y" && return 0
  return 1
}

detectCustom() {

  local file base
  CUSTOM=""

  file=$(find / -maxdepth 1 -type f -iname custom.iso | head -n 1)
  [ ! -s "$file" ] && file=$(find "$STORAGE" -maxdepth 1 -type f -iname custom.iso | head -n 1)

  if [ ! -s "$file" ] && [[ "${VERSION,,}" != "http"* ]]; then
    base=$(basename "$VERSION")
    file="$STORAGE/$base"
  fi

  if [ ! -f "$file" ] || [ ! -s "$file" ]; then
    return 0
  fi

  local size
  size="$(stat -c%s "$file")"
  [ -z "$size" ] || [[ "$size" == "0" ]] && return 0

  ISO="$file"
  CUSTOM="$ISO"
  BOOT="$STORAGE/windows.$size.iso"

  return 0
}

extractESD() {

  local iso="$1"
  local dir="$2"
  local version="$3"
  local desc="$4"
  local size size_gb space space_gb desc

  local msg="Extracting $desc bootdisk..."
  info "$msg" && html "$msg"

  if [ "$(stat -c%s "$iso")" -lt 100000000 ]; then
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
  esdImageCount=$(wimlib-imagex info "$iso" | awk '/Image Count:/ {print $3}')

  wimlib-imagex apply "$iso" 1 "$dir" --quiet 2>/dev/null || {
    retVal=$?
    error "Extracting $desc bootdisk failed" && return $retVal
  }

  local bootWimFile="$dir/sources/boot.wim"
  local installWimFile="$dir/sources/install.wim"

  local msg="Extracting $desc environment..."
  info "$msg" && html "$msg"

  wimlib-imagex export "$iso" 2 "$bootWimFile" --compress=none --quiet || {
    retVal=$?
    error "Adding WinPE failed" && return ${retVal}
  }

  local msg="Extracting $desc setup..."
  info "$msg" && html "$msg"

  wimlib-imagex export "$iso" 3 "$bootWimFile" --compress=none --boot --quiet || {
   retVal=$?
   error "Adding Windows Setup failed" && return ${retVal}
  }

  if [[ "${PLATFORM,,}" == "x64" ]]; then
    LABEL="CCCOMA_X64FRE_EN-US_DV9"
  else
    LABEL="CPBA_A64FRE_EN-US_DV9"
  fi

  local msg="Extracting $desc image..."
  info "$msg" && html "$msg"

  local edition imageIndex imageEdition
  edition=$(getCatalog "$version" "name")

  if [ -z "$edition" ]; then
    error "Invalid VERSION specified, value \"$version\" is not recognized!" && return 1
  fi

  for (( imageIndex=4; imageIndex<=esdImageCount; imageIndex++ )); do
    imageEdition=$(wimlib-imagex info "$iso" ${imageIndex} | grep '^Description:' | sed 's/Description:[ \t]*//')
    [[ "${imageEdition,,}" != "${edition,,}" ]] && continue
    wimlib-imagex export "$iso" ${imageIndex} "$installWimFile" --compress=LZMS --chunk-size 128K --quiet || {
      retVal=$?
      error "Addition of $imageIndex to the $desc image failed" && return $retVal
    }
    return 0
  done

  error "Failed to find product '$edition' in install.wim!" && return 1
}

extractImage() {

  local iso="$1"
  local dir="$2"
  local version="$3"
  local desc="local ISO"
  local size size_gb space space_gb

  if [ -z "$CUSTOM" ]; then
    desc="downloaded ISO"
    if [[ "$version" != "http"* ]]; then
      desc=$(printVersion "$version" "$desc")
    fi
  fi

  if [[ "${iso,,}" == *".esd" ]]; then
    extractESD "$iso" "$dir" "$version" "$desc" && return 0
    return 1
  fi

  local msg="Extracting $desc image..."
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

  LABEL=$(isoinfo -d -i "$iso" | sed -n 's/Volume id: //p')

  return 0
}

getPlatform() {

  local xml="$1"
  local tag="ARCH"
  local platform="x64"
  local arch

  arch=$(sed -n "/$tag/{s/.*<$tag>\(.*\)<\/$tag>.*/\1/;p}" <<< "$xml")

  case "${arch,,}" in
    "0" ) platform="x86" ;;
    "9" ) platform="x64" ;;
    "12" )platform="arm64" ;;
  esac

  echo "$platform"
  return 0
}

checkPlatform() {

  local xml="$1"
  local platform compat

  platform=$(getPlatform "$xml")

  case "${platform,,}" in
    "x86" ) compat="x64" ;;
    "x64" ) compat="$platform" ;;
    "arm64" ) compat="$platform" ;;
    * ) compat="${PLATFORM,,}" ;;
  esac

  [[ "${compat,,}" == "${PLATFORM,,}" ]] && return 0

  error "You cannot boot ${platform^^} images on a $PLATFORM CPU!"
  return 1
}

hasVersion() {

  local id="$1"
  local tag="$2"
  local xml="$3"
  local edition

  [ ! -f "/run/assets/$id.xml" ] && return 1

  edition=$(printEdition "$id" "")
  [ -z "$edition" ] && return 1
  [[ "${xml,,}" != *"<${tag,,}>${edition,,}</${tag,,}>"* ]] && return 1

  return 0
}

selectVersion() {

  local tag="$1"
  local xml="$2"
  local platform="$3"
  local id name prefer

  name=$(sed -n "/$tag/{s/.*<$tag>\(.*\)<\/$tag>.*/\1/;p}" <<< "$xml")
  [[ "$name" == *"Operating System"* ]] && name=""
  [ -z "$name" ] && return 0

  id=$(fromName "$name" "$platform")
  [ -z "$id" ] && warn "Unknown ${tag,,}: '$name'" && return 0

  prefer="$id-enterprise"
  hasVersion "$prefer" "$tag" "$xml" && echo "$prefer" && return 0

  prefer="$id-ultimate"
  hasVersion "$prefer" "$tag" "$xml" && echo "$prefer" && return 0

  prefer="$id"
  hasVersion "$prefer" "$tag" "$xml" && echo "$prefer" && return 0

  prefer=$(getVersion "$name" "$platform")

  echo "$prefer"
  return 0
}

detectVersion() {

  local xml="$1"
  local id platform

  platform=$(getPlatform "$xml")
  id=$(selectVersion "DISPLAYNAME" "$xml" "$platform")
  [ -z "$id" ] && id=$(selectVersion "PRODUCTNAME" "$xml" "$platform")
  [ -z "$id" ] && id=$(selectVersion "NAME" "$xml" "$platform")

  echo "$id"
  return 0
}

detectLanguage() {

  local xml="$1"
  local lang=""

  if [[ "$xml" == *"LANGUAGE><DEFAULT>"* ]]; then
    lang="${xml#*LANGUAGE><DEFAULT>}"
    lang="${lang%%<*}"
  else
    if [[ "$xml" == *"FALLBACK><DEFAULT>"* ]]; then
      lang="${xml#*FALLBACK><DEFAULT>}"
      lang="${lang%%<*}"
    fi
  fi

  if [ -z "$lang" ]; then
   warn "Language could not be detected from ISO!" && return 0
  fi

  local culture
  culture=$(getLanguage "$lang" "culture")
  [ -n "$culture" ] && LANGUAGE="$lang" && return 0

  warn "Invalid language detected: \"$lang\""
  return 0
}

setXML() {

  local file="/custom.xml"

  [ ! -f "$file" ] || [ ! -s "$file" ] && file="$STORAGE/custom.xml"
  [ ! -f "$file" ] || [ ! -s "$file" ] && file="/run/assets/custom.xml"
  [ ! -f "$file" ] || [ ! -s "$file" ] && file="$1"
  [ ! -f "$file" ] || [ ! -s "$file" ] && file="/run/assets/$DETECTED.xml"
  [ ! -f "$file" ] || [ ! -s "$file" ] && return 1

  XML="$file"
  return 0
}

detectImage() {

  local dir="$1"
  local version="$2"
  local desc msg find language

  XML=""

  if [ -z "$DETECTED" ] && [ -z "$CUSTOM" ]; then
    [[ "${version,,}" != "http"* ]] && DETECTED="$version"
  fi

  if [ -n "$DETECTED" ]; then

    skipVersion "${DETECTED,,}" && return 0

    if ! setXML "" && [[ "$MANUAL" != [Yy1]* ]]; then
      MANUAL="Y"
      desc=$(printEdition "$DETECTED" "this version")
      warn "the answer file for $desc was not found ($DETECTED.xml), $FB."
    fi

    return 0
  fi

  info "Detecting version from ISO image..."

  if detectLegacy "$dir"; then
    desc=$(printEdition "$DETECTED" "$DETECTED")
    info "Detected: $desc"
    return 0
  fi

  local src wim info
  src=$(find "$dir" -maxdepth 1 -type d -iname sources | head -n 1)

  if [ ! -d "$src" ]; then
    warn "failed to locate 'sources' folder in ISO image, $FB" && return 1
  fi

  wim=$(find "$src" -maxdepth 1 -type f -iname install.wim | head -n 1)
  [ ! -f "$wim" ] && wim=$(find "$src" -maxdepth 1 -type f -iname install.esd | head -n 1)

  if [ ! -f "$wim" ]; then
    warn "failed to locate 'install.wim' or 'install.esd' in ISO image, $FB" && return 1
  fi

  info=$(wimlib-imagex info -xml "$wim" | tr -d '\000')
  ! checkPlatform "$info" && exit 67

  DETECTED=$(detectVersion "$info")

  if [ -z "$DETECTED" ]; then
    msg="Failed to determine Windows version from image"
    if setXML "" || [[ "$MANUAL" == [Yy1]* ]]; then
      info "${msg}!"
    else
      MANUAL="Y"
      warn "${msg}, $FB."
    fi
    return 0
  fi

  desc=$(printEdition "$DETECTED" "$DETECTED")
  detectLanguage "$info"

  if [[ "${LANGUAGE,,}" != "en" ]] && [[ "${LANGUAGE,,}" != "en-"* ]]; then
    language=$(getLanguage "$LANGUAGE" "desc")
    desc=+" ($language)"
  fi

  info "Detected: $desc"
  setXML "" && return 0

  msg="the answer file for $desc was not found ($DETECTED.xml)"
  local fallback="/run/assets/${DETECTED%%-*}.xml"

  if setXML "$fallback" || [[ "$MANUAL" == [Yy1]* ]]; then
    [[ "$MANUAL" != [Yy1]* ]] && warn "${msg}."
  else
    MANUAL="Y"
    warn "${msg}, $FB."
  fi

  return 0
}

prepareImage() {

  local iso="$1"
  local dir="$2"
  local desc missing

  desc=$(printVersion "$DETECTED" "$DETECTED")

  ! setMachine "$DETECTED" "$iso" "$dir" "$desc" && return 1
  skipVersion "$DETECTED" && return 0

  if [[ "${BOOT_MODE,,}" != "windows_legacy" ]]; then

    [ -f "$dir/$ETFS" ] && [ -f "$dir/$EFISYS" ] && return 0

    missing=$(basename "$dir/$EFISYS")
    [ ! -f "$dir/$ETFS" ] && missing=$(basename "$dir/$ETFS")

    error "Failed to locate file \"${missing,,}\" in ISO image!"
    return 1
  fi

  prepareLegacy "$iso" "$dir" "$desc" && return 0

  error "Failed to extract boot image from ISO image!"
  return 1
}

updateXML() {

  local asset="$1"
  local language="$2"
  local culture region user admin pass keyboard

  [ -z "$YRES" ] && YRES="720"
  [ -z "$XRES" ] && XRES="1280"
  
  sed -i "s/<VerticalResolution>1080<\/VerticalResolution>/<VerticalResolution>$YRES<\/VerticalResolution>/g" "$asset"
  sed -i "s/<HorizontalResolution>1920<\/HorizontalResolution>/<HorizontalResolution>$XRES<\/HorizontalResolution>/g" "$asset"

  culture=$(getLanguage "$language" "culture")

  if [ -n "$culture" ] && [[ "${culture,,}" != "en-us" ]]; then
    sed -i "s/<UILanguage>en-US<\/UILanguage>/<UILanguage>$culture<\/UILanguage>/g" "$asset"
  fi

  region="$REGION"
  [ -z "$region" ] && region="$culture"

  if [ -n "$region" ] && [[ "${region,,}" != "en-us" ]]; then
    sed -i "s/<UserLocale>en-US<\/UserLocale>/<UserLocale>$region<\/UserLocale>/g" "$asset"
    sed -i "s/<SystemLocale>en-US<\/SystemLocale>/<SystemLocale>$region<\/SystemLocale>/g" "$asset"
  fi

  keyboard="$KEYBOARD"
  [ -z "$keyboard" ] && keyboard="$culture"

  if [ -n "$keyboard" ] && [[ "${keyboard,,}" != "en-us" ]]; then
    sed -i "s/<InputLocale>en-US<\/InputLocale>/<InputLocale>$keyboard<\/InputLocale>/g" "$asset"
    sed -i "s/<InputLocale>0409:00000409<\/InputLocale>/<InputLocale>$keyboard<\/InputLocale>/g" "$asset"
  fi

  user=$(echo "$USERNAME" | sed 's/[^[:alnum:]@!._-]//g')

  if [ -n "$user" ]; then
    sed -i "s/<Name>Docker<\/Name>/<Name>$user<\/Name>/g" "$asset"
    sed -i "s/where name=\"Docker\"/where name=\"$user\"/g" "$asset"
    sed -i "s/<FullName>Docker<\/FullName>/<FullName>$user<\/FullName>/g" "$asset"
    sed -i "s/<Username>Docker<\/Username>/<Username>$user<\/Username>/g" "$asset"
  fi

  if [ -n "$PASSWORD" ]; then
    pass=$(printf '%s' "${PASSWORD}Password" | iconv -f utf-8 -t utf-16le | base64 -w 0)
    admin=$(printf '%s' "${PASSWORD}AdministratorPassword" | iconv -f utf-8 -t utf-16le | base64 -w 0)
    sed -i "s/<Value>password<\/Value>/<Value>$admin<\/Value>/g" "$asset"
    sed -i "s/<PlainText>true<\/PlainText>/<PlainText>false<\/PlainText>/g" "$asset"
    sed -z "s/<Password>...........<Value \/>/<Password>\n          <Value>$pass<\/Value>/g" -i "$asset"
    sed -z "s/<Password>...............<Value \/>/<Password>\n              <Value>$pass<\/Value>/g" -i "$asset"
    sed -z "s/<AdministratorPassword>...........<Value \/>/<AdministratorPassword>\n          <Value>$admin<\/Value>/g" -i "$asset"
    sed -z "s/<AdministratorPassword>...............<Value \/>/<AdministratorPassword>\n              <Value>$admin<\/Value>/g" -i "$asset"
  fi

  return 0
}

addDriver() {

  local id="$1"
  local path="$2"
  local target="$3"
  local driver="$4"
  local folder=""

  case "${id,,}" in
    "win7x86"* ) folder="w7/x86" ;;
    "win7x64"* ) folder="w7/amd64" ;;
    "win81x64"* ) folder="w8.1/amd64" ;;
    "win10x64"* ) folder="w10/amd64" ;;
    "win11x64"* ) folder="w11/amd64" ;;
    "win2025"* ) folder="w11/amd64" ;;
    "win2022"* ) folder="2k22/amd64" ;;
    "win2019"* ) folder="2k19/amd64" ;;
    "win2016"* ) folder="2k16/amd64" ;;
    "win2012"* ) folder="2k12R2/amd64" ;;
    "win2008"* ) folder="2k8R2/amd64" ;;
    "win10arm64"* ) folder="w10/ARM64" ;;
    "win11arm64"* ) folder="w11/ARM64" ;;
    "winvistax86"* ) folder="2k8/x86" ;;
    "winvistax64"* ) folder="2k8/amd64" ;;
  esac

  if [ -z "$folder" ]; then
    warn "no \"$driver\" driver found for \"$DETECTED\" !" && return 0
  fi

  [ ! -d "$path/$driver/$folder" ] && return 0

  if [[ "${id,,}" == "winvista"* ]]; then
    [[ "${driver,,}" == "viorng" ]] && return 0
  fi

  local dest="$path/$target/$driver"
  mv "$path/$driver/$folder" "$dest"

  return 0
}

addDrivers() {

  local file="$1"
  local index="$2"
  local version="$3"

  local msg="Adding drivers to image..."
  info "$msg" && html "$msg"

  local drivers="$TMP/drivers"
  mkdir -p "$drivers"

  if ! tar -xf /drivers.txz -C "$drivers" --warning=no-timestamp; then
    error "Failed to extract driver!" && return 1
  fi

  local target="\$WinPEDriver\$"
  local dest="$drivers/$target"
  mkdir -p "$dest"

  wimlib-imagex update "$file" "$index" --command "delete --force --recursive /$target" >/dev/null || true

  addDriver "$version" "$drivers" "$target" "qxl"
  addDriver "$version" "$drivers" "$target" "viofs"
  addDriver "$version" "$drivers" "$target" "sriov"
  addDriver "$version" "$drivers" "$target" "smbus"
  addDriver "$version" "$drivers" "$target" "qxldod"
  addDriver "$version" "$drivers" "$target" "viorng"
  addDriver "$version" "$drivers" "$target" "viostor"
  addDriver "$version" "$drivers" "$target" "NetKVM"
  addDriver "$version" "$drivers" "$target" "Balloon"
  addDriver "$version" "$drivers" "$target" "vioscsi"
  addDriver "$version" "$drivers" "$target" "pvpanic"
  addDriver "$version" "$drivers" "$target" "vioinput"
  addDriver "$version" "$drivers" "$target" "viogpudo"
  addDriver "$version" "$drivers" "$target" "vioserial"
  addDriver "$version" "$drivers" "$target" "qemupciserial"

  if ! wimlib-imagex update "$file" "$index" --command "add $dest /$target" >/dev/null; then
    return 1
  fi

  rm -rf "$drivers"
  return 0
}

addFolder() {

  local src="$1"
  local folder="/oem"

  [ ! -d "$folder" ] && folder="/OEM"
  [ ! -d "$folder" ] && folder="$STORAGE/oem"
  [ ! -d "$folder" ] && folder="$STORAGE/OEM"
  [ ! -d "$folder" ] && return 0

  local msg="Adding OEM folder to image..."
  info "$msg" && html "$msg"

  local dest="$src/\$OEM\$/\$1/"
  mkdir -p "$dest"

  ! cp -r "$folder" "$dest" && return 1

  local file
  file=$(find "$dest" -maxdepth 1 -type f -iname install.bat | head -n 1)
  [ -f "$file" ] && unix2dos -q "$file"

  return 0
}

updateImage() {

  local dir="$1"
  local asset="$2"
  local language="$3"
  local file="autounattend.xml"
  local org="${file//.xml/.org}"
  local dat="${file//.xml/.dat}"
  local desc path src wim xml index result

  skipVersion "${DETECTED,,}" && return 0

  if [ ! -s "$asset" ] || [ ! -f "$asset" ]; then
    asset=""
    if [[ "$MANUAL" != [Yy1]* ]]; then
      MANUAL="Y"
      warn "no answer file provided, $FB."
    fi
  fi

  src=$(find "$dir" -maxdepth 1 -type d -iname sources | head -n 1)

  if [ ! -d "$src" ]; then
    error "failed to locate 'sources' folder in ISO image, $FB" && return 1
  fi

  wim=$(find "$src" -maxdepth 1 -type f -iname boot.wim | head -n 1)
  [ ! -f "$wim" ] && wim=$(find "$src" -maxdepth 1 -type f -iname boot.esd | head -n 1)

  if [ ! -f "$wim" ]; then
    error "failed to locate 'boot.wim' or 'boot.esd' in ISO image, $FB" && return 1
  fi

  index="1"
  result=$(wimlib-imagex info -xml "$wim" | tr -d '\000')

  if [[ "${result^^}" == *"<IMAGE INDEX=\"2\">"* ]]; then
    index="2"
  fi

  if ! addDrivers "$wim" "$index" "$DETECTED"; then
    error "Failed to add drivers to image!" && return 1
  fi

  if ! addFolder "$src"; then
    error "Failed to add OEM folder to image!" && return 1
  fi

  if wimlib-imagex extract "$wim" "$index" "/$file" "--dest-dir=$TMP" >/dev/null 2>&1; then
    if ! wimlib-imagex extract "$wim" "$index" "/$dat" "--dest-dir=$TMP" >/dev/null 2>&1; then
      if ! wimlib-imagex extract "$wim" "$index" "/$org" "--dest-dir=$TMP" >/dev/null 2>&1; then
        if ! wimlib-imagex update "$wim" "$index" --command "rename /$file /$org" > /dev/null; then
          warn "failed to backup original answer file ($file)."
        fi
      fi
    fi
    rm -f "$TMP/$dat"
    rm -f "$TMP/$org"
    rm -f "$TMP/$file"
  fi

  if [[ "$MANUAL" != [Yy1]* ]]; then

    xml=$(basename "$asset")
    info "Adding $xml for automatic installation..."

    local answer="$TMP/$xml"
    cp "$asset" "$answer"
    updateXML "$answer" "$language"

    if ! wimlib-imagex update "$wim" "$index" --command "add $answer /$file" > /dev/null; then
      MANUAL="Y"
      warn "failed to add answer file ($xml) to ISO image, $FB"
    else
      wimlib-imagex update "$wim" "$index" --command "add $answer /$dat" > /dev/null || true
    fi

    rm -f "$answer"

  fi

  if [[ "$MANUAL" == [Yy1]* ]]; then

    wimlib-imagex update "$wim" "$index" --command "delete --force /$file" > /dev/null || true

    if wimlib-imagex extract "$wim" "$index" "/$org" "--dest-dir=$TMP" >/dev/null 2>&1; then
      if ! wimlib-imagex update "$wim" "$index" --command "add $TMP/$org /$file" > /dev/null; then
        warn "failed to restore original answer file ($org)."
      fi
    fi

    rm -f "$TMP/$org"

  fi

  local find="$file"
  [[ "$MANUAL" == [Yy1]* ]] && find="$org"
  path=$(find "$dir" -maxdepth 1 -type f -iname "$find" | head -n 1)

  if [ -f "$path" ]; then
    if [[ "$MANUAL" != [Yy1]* ]]; then
      mv -f "$path" "${path%.*}.org"
    else
      mv -f "$path" "${path%.*}.xml"
    fi
  fi

  return 0
}

removeImage() {

  local iso="$1"

  [ ! -f "$iso" ] && return 0
  [ -n "$CUSTOM" ] && return 0
  ! rm -f "$iso" 2> /dev/null && warn "failed to remove $iso !"

  return 0
}

buildImage() {

  local dir="$1"
  local failed=""
  local cat="BOOT.CAT"
  local log="/run/shm/iso.log"
  local base size size_gb space space_gb desc

  if [ -f "$BOOT" ]; then
    error "File $BOOT does already exist?!" && return 1
  fi

  base=$(basename "$BOOT")
  local out="$TMP/${base%.*}.tmp"
  rm -f "$out"

  desc=$(printVersion "$DETECTED" "ISO")

  local msg="Building $desc image..."
  info "$msg" && html "$msg"

  [ -z "$LABEL" ] && LABEL="Windows"

  if [ ! -f "$dir/$ETFS" ]; then
    error "Failed to locate file \"$ETFS\" in ISO image!" && return 1
  fi

  size=$(du -h -b --max-depth=0 "$dir" | cut -f1)
  size_gb=$(( (size + 1073741823)/1073741824 ))
  space=$(df --output=avail -B 1 "$TMP" | tail -n 1)
  space_gb=$(( (space + 1073741823)/1073741824 ))

  if (( size > space )); then
    error "Not enough free space in $STORAGE, have $space_gb GB available but need at least $size_gb GB." && return 1
  fi

  if [[ "${BOOT_MODE,,}" != "windows_legacy" ]]; then

    ! genisoimage -o "$out" -b "$ETFS" -no-emul-boot -c "$cat" -iso-level 4 -J -l -D -N -joliet-long -relaxed-filenames -V "${LABEL::30}" \
                  -udf -boot-info-table -eltorito-alt-boot -eltorito-boot "$EFISYS" -no-emul-boot -allow-limited-size -quiet "$dir" 2> "$log" && failed="y"

  else

    case "${DETECTED,,}" in
      "win2k"* | "winxp"* | "win2003"* )
        ! genisoimage -o "$out" -b "$ETFS" -no-emul-boot -boot-load-seg 1984 -boot-load-size 4 -c "$cat" -iso-level 2 -J -l -D -N -joliet-long \
                      -relaxed-filenames -V "${LABEL::30}" -quiet "$dir" 2> "$log" && failed="y" ;;
      "win9"* )
        ! genisoimage -o "$out" -b "$ETFS" -J -r -V "${LABEL::30}" -quiet "$dir" 2> "$log" && failed="y" ;;
      * )
        ! genisoimage -o "$out" -b "$ETFS" -no-emul-boot -c "$cat" -iso-level 2 -J -l -D -N -joliet-long -relaxed-filenames -V "${LABEL::30}" \
                      -udf -allow-limited-size -quiet "$dir" 2> "$log" && failed="y" ;;
    esac

  fi

  if [ -n "$failed" ]; then
    [ -s "$log" ] && echo "$(<"$log")"
    error "Failed to build image!" && return 1
  fi

  local error=""
  local hide="Warning: creating filesystem that does not conform to ISO-9660."

  [ -s "$log" ] && error="$(<"$log")"
  [[ "$error" != "$hide" ]] && echo "$error"

  ! mv -f "$out" "$BOOT" && return 1
  return 0
}

bootWindows() {

  rm -rf "$TMP"

  if [ -s "$STORAGE/windows.vga" ] && [ -f "$STORAGE/windows.vga" ]; then
    [ -z "${VGA:-}" ] && VGA=$(<"$STORAGE/windows.vga")
  else
    [ -z "${VGA:-}" ] && [[ "${PLATFORM,,}" == "arm64" ]] && VGA="virtio-gpu"
  fi

  if [ -s "$STORAGE/windows.type" ] && [ -f "$STORAGE/windows.type" ]; then
    [ -z "${DISK_TYPE:-}" ] && DISK_TYPE=$(<"$STORAGE/windows.type")
  fi

  if [ -s "$STORAGE/windows.mode" ] && [ -f "$STORAGE/windows.mode" ]; then
    BOOT_MODE=$(<"$STORAGE/windows.mode")
    if [ -s "$STORAGE/windows.old" ] && [ -f "$STORAGE/windows.old" ]; then
      [[ "${PLATFORM,,}" == "x64" ]] && MACHINE=$(<"$STORAGE/windows.old")
    fi
    return 0
  fi

  # Migrations

  [[ "${PLATFORM,,}" != "x64" ]] && return 0

  if [ -f "$STORAGE/windows.old" ]; then
    MACHINE=$(<"$STORAGE/windows.old")
    [ -z "$MACHINE" ] && MACHINE="q35"
    BOOT_MODE="windows_legacy"
    echo "$BOOT_MODE" > "$STORAGE/windows.mode"
    return 0
  fi

  local creation="1.10"
  local minimal="2.14"

  if [ -f "$STORAGE/windows.ver" ]; then
    creation=$(<"$STORAGE/windows.ver")
    [[ "${creation}" != *"."* ]] && creation="$minimal"
  fi

  # Force secure boot on installs created prior to v2.14
  if (( $(echo "$creation < $minimal" | bc -l) )); then
    if [[ "${BOOT_MODE,,}" == "windows" ]]; then
      BOOT_MODE="windows_secure"
      echo "$BOOT_MODE" > "$STORAGE/windows.mode"
      if [ -f "$STORAGE/windows.rom" ] && [ ! -f "$STORAGE/$BOOT_MODE.rom" ]; then
        mv -f "$STORAGE/windows.rom" "$STORAGE/$BOOT_MODE.rom"
      fi
      if [ -f "$STORAGE/windows.vars" ] && [ ! -f "$STORAGE/$BOOT_MODE.vars" ]; then
        mv -f "$STORAGE/windows.vars" "$STORAGE/$BOOT_MODE.vars"
      fi
    fi
  fi

  return 0
}

######################################

! parseVersion && exit 58
! parseLanguage && exit 56
! detectCustom && exit 59

if ! startInstall; then
  bootWindows && return 0
  exit 68
fi

if [ ! -s "$ISO" ] || [ ! -f "$ISO" ]; then
  if ! downloadImage "$ISO" "$VERSION" "$LANGUAGE"; then
    rm -f "$ISO" 2> /dev/null || true
    exit 61
  fi
fi

if ! extractImage "$ISO" "$DIR" "$VERSION"; then
  rm -f "$ISO" 2> /dev/null || true
  exit 62
fi

if ! detectImage "$DIR" "$VERSION"; then
  abortInstall "$DIR" "$ISO" && return 0
  exit 60
fi

if ! prepareImage "$ISO" "$DIR"; then
  abortInstall "$DIR" "$ISO" && return 0
  exit 66
fi

if ! updateImage "$DIR" "$XML" "$LANGUAGE"; then
  abortInstall "$DIR" "$ISO" && return 0
  exit 63
fi

if ! removeImage "$ISO"; then
  exit 64
fi

if ! buildImage "$DIR"; then
  exit 65
fi

if ! finishInstall "$BOOT" "N"; then
  exit 69
fi

html "Successfully prepared image for installation..."
return 0
