#!/usr/bin/env bash
set -Eeuo pipefail

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
      url="https://go.microsoft.com/fwlink?linkid=2156292" ;;
    "win10${PLATFORM,,}" )
      edition="Professional"
      name="Windows 10 Pro"
      url="https://go.microsoft.com/fwlink/?LinkId=841361" ;;
  esac

  case "${ret,,}" in
    "url" ) echo "$url" ;;
    "name" ) echo "$name" ;;
    "edition" ) echo "$edition" ;;
    *) echo "";;
  esac

  return 0
}

getESD() {

  local dir="$1"
  local version="$2"
  local lang="$3"
  local desc="$4"
  local culture
  local language
  local editionName
  local winCatalog size

  culture=$(getLanguage "$lang" "culture")
  winCatalog=$(getCatalog "$version" "url")
  editionName=$(getCatalog "$version" "edition")

  if [ -z "$winCatalog" ] || [ -z "$editionName" ]; then
    error "Invalid VERSION specified, value \"$version\" is not recognized!" && return 1
  fi

  local msg="Downloading product information from Microsoft server..."
  info "$msg" && html "$msg"

  rm -rf "$dir"
  mkdir -p "$dir"

  local wFile="catalog.cab"
  local xFile="products.xml"
  local eFile="esd_edition.xml"
  local fFile="products_filter.xml"

  { wget "$winCatalog" -O "$dir/$wFile" -q --timeout=30; rc=$?; } || :
  (( rc == 4 )) && error "Failed to download $winCatalog , network failure!" && return 1
  (( rc != 0 )) && error "Failed to download $winCatalog , reason: $rc" && return 1

  cd "$dir"

  if ! cabextract "$wFile" > /dev/null; then
    cd /run
    error "Failed to extract $wFile!" && return 1
  fi

  cd /run

  if [ ! -s "$dir/$xFile" ]; then
    error "Failed to find $xFile in $wFile!" && return 1
  fi

  local edQuery='//File[Architecture="'${PLATFORM}'"][Edition="'${editionName}'"]'

  echo -e '<Catalog>' > "$dir/$fFile"
  xmllint --nonet --xpath "${edQuery}" "$dir/$xFile" >> "$dir/$fFile" 2>/dev/null
  echo -e '</Catalog>'>> "$dir/$fFile"

  xmllint --nonet --xpath '//File[LanguageCode="'${culture,,}'"]' "$dir/$fFile" >"$dir/$eFile"

  size=$(stat -c%s "$dir/$eFile")
  if ((size<20)); then
    language=$(getLanguage "$lang" "desc")
    error "the $language language is not supported by this download method!" && return 1
  fi

  local tag="FilePath"
  ESD=$(xmllint --nonet --xpath "//$tag" "$dir/$eFile" | sed -E -e "s/<[\/]?$tag>//g")

  if [ -z "$ESD" ]; then
    error "Failed to find ESD URL in $eFile!" && return 1
  fi

  tag="Sha1"
  ESD_SUM=$(xmllint --nonet --xpath "//$tag" "$dir/$eFile" | sed -E -e "s/<[\/]?$tag>//g")
  tag="Size"
  ESD_SIZE=$(xmllint --nonet --xpath "//$tag" "$dir/$eFile" | sed -E -e "s/<[\/]?$tag>//g")

  rm -rf "$dir"
  return 0
}

verifyFile() {

  local iso="$1"
  local size="$2"
  local total="$3"
  local check="$4"

  if [ -n "$size" ] && [[ "$total" != "$size" ]] && [[ "$size" != "0" ]]; then
    warn "The downloaded file has an unexpected size: $total bytes, while expected value was: $size bytes. Please report this at $SUPPORT/issues"
  fi

  local hash=""
  local algo="SHA256"

  [ -z "$check" ] && return 0
  [[ "$VERIFY" != [Yy1]* ]] && return 0
  [[ "${#check}" == "40" ]] && algo="SHA1"

  local msg="Verifying downloaded ISO..."
  info "$msg" && html "$msg"

  if [[ "${algo,,}" != "sha256" ]]; then
    hash=$(sha1sum "$iso" | cut -f1 -d' ')
  else
    hash=$(sha256sum "$iso" | cut -f1 -d' ')
  fi

  if [[ "$hash" == "$check" ]]; then
    info "Succesfully verified ISO!" && return 0
  fi

  error "The downloaded file has an invalid $algo checksum: $hash , while expected value was: $check. Please report this at $SUPPORT/issues"

  rm -f "$iso"
  return 1
}

downloadFile() {

  local iso="$1"
  local url="$2"
  local sum="$3"
  local size="$4"
  local lang="$5"
  local desc="$6"
  local rc total progress domain dots

  rm -f "$iso"

  # Check if running with interactive TTY or redirected to docker log
  if [ -t 1 ]; then
    progress="--progress=bar:noscroll"
  else
    progress="--progress=dot:giga"
  fi

  local msg="Downloading $desc..."
  html "$msg"

  domain=$(echo "$url" | awk -F/ '{print $3}')
  dots=$(echo "$domain" | tr -cd '.' | wc -c)
  (( dots > 1 )) && domain=$(expr "$domain" : '.*\.\(.*\..*\)')

  if [ -n "$domain" ] && [[ "${domain,,}" != *"microsoft.com" ]]; then
    msg="Downloading $desc from $domain..."
  fi

  info "$msg"
  /run/progress.sh "$iso" "$size" "Downloading $desc ([P])..." &

  { wget "$url" -O "$iso" -q --timeout=30 --show-progress "$progress"; rc=$?; } || :

  fKill "progress.sh"

  if (( rc == 0 )) && [ -f "$iso" ]; then
    total=$(stat -c%s "$iso")
    if [ "$total" -gt 100000000 ]; then
      ! verifyFile "$iso" "$size" "$total" "$sum" && return 1
      html "Download finished successfully..." && return 0
    fi
  fi

  if (( rc != 4 )); then
    error "Failed to download $url , reason: $rc"
  else
    error "Failed to download $url , network failure!"
  fi

  rm -f "$iso"
  return 1
}

downloadImage() {

  local iso="$1"
  local version="$2"
  local lang="$3"
  local tried="n"
  local url sum size base desc language

  if [[ "${version,,}" == "http"* ]]; then
    base=$(basename "$iso")
    desc=$(fromFile "$base")
    downloadFile "$iso" "$version" "" "" "" "$desc" && return 0
    return 1
  fi

  if ! validVersion "$version" "en"; then
    error "Invalid VERSION specified, value \"$version\" is not recognized!" && return 1
  fi

  desc=$(printVersion "$version" "")

  if [[ "${lang,,}" != "en" ]] && [[ "${lang,,}" != "en-"* ]]; then
    language=$(getLanguage "$lang" "desc")
    if ! validVersion "$version" "$lang"; then
      desc=$(printEdition "$version" "$desc")
      error "The $language language version of $desc is not available, please switch to English." && return 1
    fi
    desc="$desc in $language"
  fi

  if isESD "$version" "$lang"; then

    if [[ "$tried" != "n" ]]; then
      info "Failed to download $desc, will try a diferent method now..."
    fi

    tried="y"

    if getESD "$TMP/esd" "$version" "$lang" "$desc"; then
      ISO="${ISO%.*}.esd"
      downloadFile "$ISO" "$ESD" "$ESD_SUM" "$ESD_SIZE" "$lang" "$desc" && return 0
      ISO="$iso"
    fi

  fi

  for ((i=1;i<=MIRRORS;i++)); do

    url=$(getLink "$i" "$version" "$lang")

    if [ -n "$url" ]; then
      if [[ "$tried" != "n" ]]; then
        info "Failed to download $desc, will try another mirror now..."
      fi
      tried="y"
      size=$(getSize "$i" "$version" "$lang")
      sum=$(getHash "$i" "$version" "$lang")
      downloadFile "$iso" "$url" "$sum" "$size" "$lang" "$desc" && return 0
    fi

  done

  return 1
}

return 0
