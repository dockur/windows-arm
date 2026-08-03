#!/usr/bin/env bash
set -Eeuo pipefail

: "${KEY:=""}"
: "${HOST:=""}"
: "${WIDTH:=""}"
: "${HEIGHT:=""}"
: "${VERIFY:=""}"
: "${DOMAIN:=""}"
: "${REGION:=""}"
: "${EDITION:=""}"
: "${MANUAL:=""}"
: "${REMOVE:=""}"
: "${VERSION:=""}"
: "${COMMAND:=""}"
: "${DETECTED:=""}"
: "${KEYBOARD:=""}"
: "${LANGUAGE:=""}"
: "${USERNAME:=""}"
: "${PASSWORD:=""}"
: "${SHORTCUT:=""}"
: "${DOMAIN_OU:=""}"
: "${WORKGROUP:=""}"
: "${AUTOLOGIN:=""}"

# Sanitize variables
KEY=$(strip "$KEY")
HOST=$(strip "$HOST")
WIDTH=$(strip "$WIDTH")
HEIGHT=$(strip "$HEIGHT")
DOMAIN=$(strip "$DOMAIN")
REGION=$(strip "$REGION")
EDITION=$(strip "$EDITION")
KEYBOARD=$(strip "$KEYBOARD")
LANGUAGE=$(strip "$LANGUAGE")
USERNAME=$(strip "$USERNAME")
DOMAIN_OU=$(strip "$DOMAIN_OU")
WORKGROUP=$(strip "$WORKGROUP")

MIRRORS=4

parseVersion() {

  SUGGEST=""
  VERSION=$(strip "$VERSION")
  [ -z "$VERSION" ] && VERSION="win11"

  local msg="is not available for ARM64 CPU's."

  case "${VERSION,,}" in
    "11" | "11p" | "win11" | "pro11" | "win11p" | "windows11" | "windows 11" )
      VERSION="win11arm64"
      ;;
    "11e" | "win11e" | "windows11e" | "windows 11e" )
      VERSION="win11arm64-enterprise-eval"
      ;;
    "11l" | "11ltsc" | "ltsc11" | "win11l" | "win11-ltsc" | "win11arm64-ltsc" )
      VERSION="win11arm64-enterprise-ltsc-eval"
      ;;
    "11i" | "11iot" | "iot11" | "win11i" | "win11-iot" | "win11arm64-iot" )
      VERSION="win11arm64-enterprise-iot-eval"
      ;;
    "10" | "10p" | "win10" | "pro10" | "win10p" | "windows10" | "windows 10" )
      VERSION="win10arm64"
      ;;
    "10e" | "win10e" | "windows10e" | "windows 10e" )
      VERSION="win10arm64-enterprise-eval"
      ;;
    "10l" | "10ltsc" | "ltsc10" | "win10l" | "win10-ltsc" | "win10arm64-ltsc" )
      VERSION="win10arm64-enterprise-ltsc-eval"
      ;;
    "10i" | "10iot" | "iot10" | "win10i" | "win10-iot" | "win10arm64-iot" )
      VERSION="win10arm64-enterprise-iot-eval"
      ;;
    "8" | "8p" | "81" | "81p" | "pro8" | "8.1" | "win8" | "win8p" | "win81" | "win81p" | "windows 8" | \
    "8e" | "81e" | "8.1e" | "win8e" | "win81e" | "windows 8e" )
      error "Windows 8 $msg" && return 1
      ;;
    "7" | "win7" | "windows7" | "windows 7" | "7u" | "win7u" | "windows7u" | "windows 7u" | "7e" | \
    "win7e" | "windows7e" | "windows 7e" | "7x86" | "win7x86" | "win732" | "windows7x86" | "7ux86" | \
    "7u32" | "win7x86-ultimate" | "7ex86" | "7e32" | "win7x86-enterprise" )
      error "Windows 7 $msg" && return 1
      ;;
    "vista" | "vs" | "6" | "winvista" | "windowsvista" | "windows vista" | "vistu" | "vu" | "6u" | "winvistu" | \
    "viste" | "ve" | "6e" | "winviste" | "vistax86" | "vista32" | "6x86" | "winvistax86" | "windowsvistax86" | \
    "vux86" | "vu32" | "winvistax86-ultimate" | "vex86" | "ve32" | "winvistax86-enterprise" )
      error "Windows Vista $msg" && return 1
      ;;
    "xp" | "xp32" | "xpx86" | "5" | "5x86" | "winxp" | "winxp86" | "windowsxp" | "windows xp" | \
    "xp64" | "xpx64" | "5x64" | "winxp64" | "winxpx64" | "windowsxp64" | "windowsxpx64" )
      error "Windows XP $msg" && return 1
      ;;
    "2k" | "2000" | "win2k" | "win2000" | "windows2k" | "windows2000" )
      error "Windows 2000 $msg" && return 1
      ;;
    "25" | "2025" | "win25" | "win2025" | "windows2025" | "windows 2025" )
      error "Windows Server 2025 $msg" && return 1
      ;;
    "22" | "2022" | "win22" | "win2022" | "windows2022" | "windows 2022" )
      error "Windows Server 2022 $msg" && return 1
      ;;
    "19" | "2019" | "win19" | "win2019" | "windows2019" | "windows 2019" )
      error "Windows Server 2019 $msg" && return 1
      ;;
    "16" | "2016" | "win16" | "win2016" | "windows2016" | "windows 2016" )
      error "Windows Server 2016 $msg" && return 1
      ;;
    "hv" | "hyperv" | "hyper v" | "hyper-v" | "19hv" | "2019hv" | "win2019hv" )
      error "Hyper-V Server 2019 $msg" && return 1
      ;;
    "2012" | "2012r2" | "win2012" | "win2012r2" | "windows2012" | "windows 2012" )
      error "Windows Server 2012 $msg" && return 1
      ;;
    "2008" | "2008r2" | "win2008" | "win2008r2" | "windows2008" | "windows 2008" )
      error "Windows Server 2008 $msg" && return 1
      ;;
    "2003" | "2003r2" | "win2003" | "win2003r2" | "windows2003" | "windows 2003" )
      error "Windows Server 2003 $msg" && return 1
      ;;
    "tiny11" | "tiny 11" )
      VERSION="tiny11"
      ;;
    "core11" | "core 11" )
      VERSION="core11"
      ;;
    "tiny10" | "tiny 10" )
      error "Tiny 10 $msg" && return 1
      ;;
    "reactos" | "react os" )
      error "Reactos $msg" && return 1
      ;;
  esac

  SUGGEST=$(getSuggestedVersion "$VERSION")

  if ! isCompatible; then

    msg="your CPU architecture is below ARMv8.1, and does not support Windows 11 build 24H2 and up."

    case "${SUGGEST,,}|${VERSION,,}" in
      "win11arm64|"* | "win11arm64-enterprise|"* )
        warn "$msg"
        ;;
      *"|win11"* | *"|tiny11"* | *"|core11"* )
        error "$msg"
        return 1
        ;;
    esac

  fi

  return 0
}

getSuggestedVersion() {

  local id="${1,,}"

  [[ "$id" == http* ]] && return 0

  case "$id" in
    "win10arm64" | "win11arm64" )
      echo "$id"
      ;;
    *"-enterprise-ltsc-eval" )
      echo "${id%-enterprise-ltsc-eval}-ltsc"
      ;;
    *"-enterprise-iot-eval" )
      echo "${id%-enterprise-iot-eval}-iot"
      ;;
    *"-enterprise-ltsc" )
      echo "${id%-enterprise-ltsc}-ltsc"
      ;;
    *"-enterprise-iot" )
      echo "${id%-enterprise-iot}-iot"
      ;;
    *"-eval" )
      echo "${id%-eval}"
      ;;
  esac

  return 0
}

getLanguage() {

  local source="$1"
  local input="${1,,}"
  local ret="$2"
  local id="$source"
  local lang=""
  local desc=""
  local short=""
  local culture=""

  case "$input" in
    "ar" | "ar-"* | "arabic" | "arab" )
      [[ "$input" == "arabic" || "$input" == "arab" ]] && id="ar"
      short="ar"
      lang="Arabic"
      culture="ar-SA" ;;
    "bg" | "bg-"* | "bulgarian" | "bu" )
      [[ "$input" == "bulgarian" || "$input" == "bu" ]] && id="bg"
      short="bg"
      lang="Bulgarian"
      culture="bg-BG" ;;
    "cs" | "cs-"* | "cz" | "cz-"* | "czech" | "cesky" )
      [[ "$input" == "cz" || "$input" == "czech" || "$input" == "cesky" ]] && id="cs"
      short="cs"
      lang="Czech"
      culture="cs-CZ" ;;
    "da" | "da-"* | "dk" | "dk-"* | "danish" | "danske" )
      [[ "$input" == "dk" || "$input" == "danish" || "$input" == "danske" ]] && id="da"
      short="da"
      lang="Danish"
      culture="da-DK" ;;
    "de" | "de-"* | "german" | "deutsch" )
      [[ "$input" == "german" || "$input" == "deutsch" ]] && id="de"
      short="de"
      lang="German"
      culture="de-DE" ;;
    "el" | "el-"* | "gr" | "gr-"* | "greek" )
      [[ "$input" == "gr" || "$input" == "greek" ]] && id="el"
      short="el"
      lang="Greek"
      culture="el-GR" ;;
    "gb" | "en-gb" | "british" )
      [[ "$input" == "gb" || "$input" == "british" ]] && id="en-gb"
      short="en-gb"
      lang="English International"
      desc="English"
      culture="en-GB" ;;
    "en" | "en-"* | "english" )
      [[ "$input" == "english" ]] && id="en"
      short="en"
      lang="English"
      culture="en-US" ;;
    "mx" | "es-mx" )
      short="mx"
      lang="Spanish (Mexico)"
      desc="Spanish"
      culture="es-MX" ;;
    "es" | "es-"* | "spanish" | "espanol" | "español" )
      [[ "$input" == "spanish" || "$input" == "espanol" || "$input" == "español" ]] && id="es"
      short="es"
      lang="Spanish"
      culture="es-ES" ;;
    "et" | "et-"* | "estonian" | "eesti" )
      [[ "$input" == "estonian" || "$input" == "eesti" ]] && id="et"
      short="et"
      lang="Estonian"
      culture="et-EE" ;;
    "fi" | "fi-"* | "finnish" | "suomi" )
      [[ "$input" == "finnish" || "$input" == "suomi" ]] && id="fi"
      short="fi"
      lang="Finnish"
      culture="fi-FI" ;;
    "ca" | "fr-ca" )
      short="ca"
      lang="French Canadian"
      desc="French"
      culture="fr-CA" ;;
    "fr" | "fr-"* | "french" | "français" | "francais" )
      [[ "$input" == "french" || "$input" == "français" || "$input" == "francais" ]] && id="fr"
      short="fr"
      lang="French"
      culture="fr-FR" ;;
    "he" | "he-"* | "il" | "il-"* | "hebrew" )
      [[ "$input" == "il" || "$input" == "hebrew" ]] && id="he"
      short="he"
      lang="Hebrew"
      culture="he-IL" ;;
    "hr" | "hr-"* | "cr" | "cr-"* | "croatian" | "hrvatski" )
      [[ "$input" == "cr" || "$input" == "croatian" || "$input" == "hrvatski" ]] && id="hr"
      short="hr"
      lang="Croatian"
      culture="hr-HR" ;;
    "hu" | "hu-"* | "hungarian" | "magyar" )
      [[ "$input" == "hungarian" || "$input" == "magyar" ]] && id="hu"
      short="hu"
      lang="Hungarian"
      culture="hu-HU" ;;
    "it" | "it-"* | "italian" | "italiano" )
      [[ "$input" == "italian" || "$input" == "italiano" ]] && id="it"
      short="it"
      lang="Italian"
      culture="it-IT" ;;
    "ja" | "ja-"* | "jp" | "jp-"* | "japanese" )
      [[ "$input" == "jp" || "$input" == "japanese" ]] && id="ja"
      short="ja"
      lang="Japanese"
      culture="ja-JP" ;;
    "ko" | "ko-"* | "kr" | "kr-"* | "korean" )
      [[ "$input" == "kr" || "$input" == "korean" ]] && id="ko"
      short="ko"
      lang="Korean"
      culture="ko-KR" ;;
    "lt" | "lt-"* | "lithuanian" | "lietuvos" )
      [[ "$input" == "lithuanian" || "$input" == "lietuvos" ]] && id="lt"
      short="lt"
      lang="Lithuanian"
      culture="lt-LT" ;;
    "lv" | "lv-"* | "latvian" | "latvijas" )
      [[ "$input" == "latvian" || "$input" == "latvijas" ]] && id="lv"
      short="lv"
      lang="Latvian"
      culture="lv-LV" ;;
    "nb" | "nb-"* | "nn" | "nn-"* | "no" | "no-"* | "norwegian" | "norsk" )
      [[ "$input" == "nb" || "$input" == "no" || "$input" == "norwegian" || "$input" == "norsk" ]] && id="nn"
      short="no"
      lang="Norwegian"
      culture="nb-NO" ;;
    "nl" | "nl-"* | "dutch" | "nederlands" )
      [[ "$input" == "dutch" || "$input" == "nederlands" ]] && id="nl"
      short="nl"
      lang="Dutch"
      culture="nl-NL" ;;
    "pl" | "pl-"* | "polish" | "polski" )
      [[ "$input" == "polish" || "$input" == "polski" ]] && id="pl"
      short="pl"
      lang="Polish"
      culture="pl-PL" ;;
    "br" | "pt" | "pt-br" | "portuguese" | "português" | "portugues" )
      [[ "$input" != "pt-br" ]] && id="pt-br"
      short="pt"
      lang="Brazilian Portuguese"
      desc="Portuguese"
      culture="pt-BR" ;;
    "pt-"* )
      short="pp"
      lang="Portuguese"
      culture="pt-BR" ;;
    "ro" | "ro-"* | "romanian" | "română" | "romana" )
      [[ "$input" == "romanian" || "$input" == "română" || "$input" == "romana" ]] && id="ro"
      short="ro"
      lang="Romanian"
      culture="ro-RO" ;;
    "ru" | "ru-"* | "russian" | "ruski" )
      [[ "$input" == "russian" || "$input" == "ruski" ]] && id="ru"
      short="ru"
      lang="Russian"
      culture="ru-RU" ;;
    "sk" | "sk-"* | "slovak" | "slovenský" | "slovensky" )
      [[ "$input" == "slovak" || "$input" == "slovenský" || "$input" == "slovensky" ]] && id="sk"
      short="sk"
      lang="Slovak"
      culture="sk-SK" ;;
    "sl" | "sl-"* | "si" | "si-"* | "slovenian" | "slovenski" )
      [[ "$input" == "si" || "$input" == "slovenian" || "$input" == "slovenski" ]] && id="sl"
      short="sl"
      lang="Slovenian"
      culture="sl-SI" ;;
    "sr" | "sr-"* | "serbian" | "serbian latin" )
      [[ "$input" == "serbian" || "$input" == "serbian latin" ]] && id="sr"
      short="sr"
      lang="Serbian Latin"
      desc="Serbian"
      culture="sr-Latn-RS" ;;
    "sv" | "sv-"* | "se" | "se-"* | "swedish" | "svenska" )
      [[ "$input" == "se" || "$input" == "swedish" || "$input" == "svenska" ]] && id="sv"
      short="sv"
      lang="Swedish"
      culture="sv-SE" ;;
    "th" | "th-"* | "thai" )
      [[ "$input" == "thai" ]] && id="th"
      short="th"
      lang="Thai"
      culture="th-TH" ;;
    "tr" | "tr-"* | "turkish" | "türk" | "turk" )
      [[ "$input" == "turkish" || "$input" == "türk" || "$input" == "turk" ]] && id="tr"
      short="tr"
      lang="Turkish"
      culture="tr-TR" ;;
    "ua" | "ua-"* | "uk" | "uk-"* | "ukrainian" )
      [[ "$input" == "ua" || "$input" == "ukrainian" ]] && id="uk"
      short="uk"
      lang="Ukrainian"
      culture="uk-UA" ;;
    "hk" | "zh-hk" | "cn-hk" )
      short="hk"
      lang="Chinese (Traditional)"
      desc="Chinese HK"
      culture="zh-TW" ;;
    "tw" | "zh-tw" | "cn-tw" )
      short="tw"
      lang="Chinese (Traditional)"
      desc="Chinese TW"
      culture="zh-TW" ;;
    "zh" | "zh-"* | "cn" | "cn-"* | "chinese" )
      [[ "$input" == "cn" || "$input" == "chinese" ]] && id="zh"
      short="cn"
      lang="Chinese (Simplified)"
      desc="Chinese"
      culture="zh-CN" ;;
  esac

  [ -z "$lang" ] && return 0
  [ -z "$desc" ] && desc="$lang"

  case "${ret,,}" in
    "id" ) echo "$id" ;;
    "desc" ) echo "$desc" ;;
    "name" ) echo "$lang" ;;
    "code" ) echo "$short" ;;
    "culture" ) echo "$culture" ;;
    * ) echo "$desc";;
  esac

  return 0
}

parseLanguage() {

  REGION="${REGION//_/-}"
  KEYBOARD="${KEYBOARD//_/-}"
  LANGUAGE="${LANGUAGE//_/-}"

  [ -z "$LANGUAGE" ] && LANGUAGE="en"

  local id
  id=$(getLanguage "$LANGUAGE" "id")

  if [ -z "$id" ]; then
    error "Invalid LANGUAGE specified, value \"$LANGUAGE\" is not recognized!"
    return 1
  fi

  LANGUAGE="$id"
  return 0
}

printVersion() {

  local id="$1"
  local desc="$2"

  case "${id,,}" in
    "tiny11"* ) desc="Tiny 11" ;;
    "core11"* ) desc="Core 11" ;;
    "win10"* ) desc="Windows 10" ;;
    "win11"* ) desc="Windows 11" ;;
  esac

  if [ -z "$desc" ]; then
    desc="Windows"
    [[ "${PLATFORM,,}" != "x64" ]] && desc+=" for ${PLATFORM}"
  fi

  echo "$desc"
  return 0
}

printVariant() {

  local id="$1"
  local desc="$2"
  local show_eval="${3:-N}"

  desc=$(printVersion "$id" "$desc") || return 1

  case "${id,,}" in
    *"-iot" | *"-iot-eval" ) desc+=" IoT" ;;
    *"-ltsc" | *"-ltsc-eval" ) desc+=" LTSC" ;;
    *"-enterprise" | *"-enterprise-eval" ) desc+=" Enterprise" ;;
  esac

  if enabled "$show_eval" && [[ "${id,,}" == *"-eval" ]]; then
    desc+=" (Evaluation)"
  fi

  echo "$desc"
  return 0
}

formatEdition() {

  local edition="${1//-/ }"
  local result="" word

  for word in $edition; do
    if [ "$word" == "for" ]; then
      word="for"
    elif [ "${#word}" -eq 1 ]; then
      word="${word^^}"
    else
      word="${word^}"
    fi

    result+="${result:+ }$word"
  done

  echo "$result"
  return 0
}

printEdition() {

  local id="$1"
  local desc="$2"
  local show_eval="${3:-N}"
  local normalized="${id,,}"
  local result edition="" suffix=""

  result=$(printVersion "$id" "x")
  [[ "$result" == "x" ]] && echo "$desc" && return 0

  normalized="${normalized%-eval}"

  case "$normalized" in
    "win10"* | "win11"* )
      [[ "$normalized" == *"-"* ]] && suffix="${normalized#*-}"

      case "$suffix" in
        "" ) edition="Pro" ;;
        "n" ) edition="Pro N" ;;
        "home" ) edition="Home" ;;
        "starter" ) edition="Starter" ;;
        "ultimate" ) edition="Ultimate" ;;
        "enterprise" ) edition="Enterprise" ;;
        "education" ) edition="Education" ;;
        "iot" | "enterprise-iot" ) edition="IoT Enterprise LTSC" ;;
        "ltsc" | "enterprise-ltsc" ) edition="Enterprise LTSC" ;;
        * ) edition=$(formatEdition "$suffix") ;;
      esac
      ;;
  esac

  [ -n "$edition" ] && result+=" $edition"

  if enabled "$show_eval" && [[ "${id,,}" == *"-eval" ]]; then
    result+=" (Evaluation)"
  fi

  echo "$result"
  return 0
}

fromFile() {

  local id=""
  local desc="$1"
  local file="${1,,}"
  local arch="${PLATFORM,,}"

  file="${file//-/_}"
  file="${file// /_}"

  case "$file" in
    *"_x64_"* | *"_x64."*) arch="x64" ;;
    *"_x86_"* | *"_x86."*) arch="x86" ;;
    *"_arm64_"* | *"_arm64."*) arch="arm64" ;;
  esac

  case "$file" in
    "tiny11core"* | "tiny11_core"* | "tiny_11_core"* )
      id="core11" ;;
    "tiny11"* | "tiny_11"* )
      id="tiny11" ;;
    "win10"*| "win_10"* | *"windows10"* | *"windows_10"* )
      id="win10${arch}" ;;
    "win11"* | "win_11"* | *"windows11"* | *"windows_11"* )
      id="win11${arch}" ;;
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
  local arch="$2"

  case "${name,,}" in
    *"windows 10"* ) id="win10${arch}" ;;
    *"optimum 10"* ) id="win10${arch}" ;;
    *"windows 11"* ) id="win11${arch}" ;;
    *"optimum 11"* ) id="win11${arch}" ;;
  esac

  echo "$id"
  return 0
}

isClientEdition() {
  case "${1,,}" in
    "pro" | "professional" | "business" | \
    "enterprise" | "ultimate" | "education" | \
    "home" | "homepremium" | "home-premium" | \
    "homebasic" | "home-basic" | "starter" | "core" )
      return 0 ;;
  esac
  return 1
}

normalizeEdition() {

  local source="${1,,}"
  local edition

  source="${source//evaluation/}"

  source=$(printf '%s' "$source" |
    uconv -x 'Any-Latin; Latin-ASCII' 2>/dev/null) || return 1

  edition=$(sed -E \
    -e 's/[^a-z0-9]+/-/g' \
    -e 's/^-+//' \
    -e 's/-+$//' \
    <<< "$source")

  echo "$edition"
  return 0
}

normalizeEditionID() {

  local edition base
  local id="$2"

  edition=$(normalizeEdition "$1")

  case "$edition" in
    "pro" | "professional" | "business" )
      edition="" ;;
    "pro-n" | "pron" | "professional-n" | "professionaln" | "business-n" | "businessn" )
      edition="n" ;;
    * )
      if ! isClientEdition "$edition"; then

        case "$edition" in
          *"-n" ) base="${edition%-n}" ;;
          *"n" ) base="${edition%n}" ;;
          * ) base="" ;;
        esac

        if [ -n "$base" ] && isClientEdition "$base"; then
          edition="$base-n"
        fi

      fi ;;
  esac

  case "${id,,}" in
    "win10"* | "win11"* )
      case "$edition" in
        "iot-enterprise-ltsc" | \
        "iot-enterprise-ltsc-"[0-9][0-9][0-9][0-9] )
          edition="iot" ;;
        "enterprise-ltsc" | \
        "enterprise-ltsc-"[0-9][0-9][0-9][0-9] )
          edition="ltsc" ;;
      esac
      ;;
  esac

  echo "$edition"
  return 0
}

getEditionID() {

  local name="${1,,}"
  local id="${2,,}"
  local edition

  case "$id" in
    "win10"* ) edition="${name#*10}" ;;
    "win11"* ) edition="${name#*11}" ;;
    * ) return 1 ;;
  esac

  edition=$(normalizeEditionID "$edition" "$id")

  echo "$edition"
  return 0
}

normalizeServerEdition() {

  : "${1:-}"
  return 0
}

normalizeServerEditionID() {

  : "${1:-}"
  return 0
}

getServerEditionID() {

  : "${1:-}" "${2:-}"
  return 0
}

getEditionOrder() {

  : "$1"
  local -n geo_result="$2"

  geo_result=(
    "-enterprise|enterprise|enterprise enterprise-*"
    "-ultimate|ultimate|ultimate ultimate-*"
    "|default|@default n pro pro-* professional professional-* business business-*"
    "-iot|iot|iot iot-* enterprise-iot enterprise-iot-*"
    "-ltsc|ltsc|ltsc ltsc-* enterprise-ltsc enterprise-ltsc-*"
    "-education|education|education education-* pro-education pro-education-*"
    "-home|home|home home-*"
    "-home-premium|home|home-premium home-premium-*"
    "-home-basic|home|home-basic home-basic-*"
    "-starter|starter|starter starter-*"
  )

  return 0
}

getVersion() {

  local id edition
  local name="$1"
  local arch="$2"
  local evaluation=""

  id=$(fromName "$name" "$arch")
  [[ "${name,,}" == *"evaluation"* ]] && evaluation="-eval"

  case "${id,,}" in
    "win10"* | "win11"* )
      if edition=$(getEditionID "$name" "$id"); then
        [ -n "$edition" ] && id+="-$edition"
        [ -n "$evaluation" ] && id+="$evaluation"
      fi
      ;;
  esac

  echo "$id"
  return 0
}

skipVersion() {

  : "$1"

  return 0
}

isLegacy() {

  : "$1"

  return 1
}

switchEdition() {

  local -n se_id="$1"

  [[ "${se_id,,}" == *"-eval" ]] || return 1

  se_id="${se_id::-5}"

  if ! enabled "${DETECTED_ORG:-}"; then
    DETECTED="${SUGGEST:-$se_id}"
  fi

  return 0
}

getMido() {

  local id="$1"
  local lang="$2"
  local ret="$3"
  local url=""
  local sum=""
  local size=""

  [[ "${id,,}" == "win11"* ]] && ! isCompatible && return 0
  [[ "${lang,,}" != "en" && "${lang,,}" != "en-us" ]] && return 0

  case "${id,,}" in
    "win11arm64" )
      size=7299147776
      sum="32cde0071ed8086b29bb6c8c3bf17ba9e3cdf43200537434a811a9b6cc2711a1"
      url="https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENT_CONSUMER_a64fre_en-us.iso"
      ;;
    "win11arm64-enterprise-eval" )
      size=4295096320
      sum="dad633276073f14f3e0373ef7e787569e216d54942ce522b39451c8f2d38ad43"
      url="https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1.240331-1435.ge_release_CLIENTENTERPRISEEVAL_OEMRET_A64FRE_en-us.iso"
      ;;
    "win11arm64-enterprise-ltsc-eval" )
      size=5042194432
      sum="3dcdba9c9c0aa0430d4332b60c9afcb3cd613d648a49cbba2d4ef7b5978f32e8"
      url="https://software-static.download.prss.microsoft.com/dbazure/998969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_IOT_LTSC_EVAL_A64FRE_en-us.iso"
      ;;
    "win11arm64-enterprise-iot-eval" )
      size=5042194432
      sum="3dcdba9c9c0aa0430d4332b60c9afcb3cd613d648a49cbba2d4ef7b5978f32e8"
      url="https://software-static.download.prss.microsoft.com/dbazure/998969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_IOT_LTSC_EVAL_A64FRE_en-us.iso"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    * ) echo "$url";;
  esac

  return 0
}

getLink1() {

  # Fallbacks for users who cannot connect to the Microsoft servers

  local id="$1"
  local lang="$2"
  local ret="$3"
  local url=""
  local sum=""
  local size=""
  local host="https://dl.bobpony.com/windows"

  [[ "${id,,}" == "win11"* ]] && ! isCompatible && return 0
  [[ "${lang,,}" != "en" && "${lang,,}" != "en-us" ]] && return 0

  case "${id,,}" in
    "win11arm64" | "win11arm64-enterprise" )
      size=6812594176
      sum="8d208f5a09de418fa6c3731b3c78410a1eecd9593ac774d820065f8d0a0f697c"
      url="11/en-us_windows_11_25h2_arm64.iso"
      ;;
    "win11arm64-ltsc" | "win11arm64-enterprise-ltsc" )
      size=5121449984
      sum="f8f068cdc90c894a55d8c8530db7c193234ba57bb11d33b71383839ac41246b4"
      url="11/X23-81950_26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_ENTERPRISES_OEM_A64FRE_en-us.iso"
      ;;
    "win11arm64-iot" | "win11arm64-enterprise-iot" )
      size=5121449984
      sum="f8f068cdc90c894a55d8c8530db7c193234ba57bb11d33b71383839ac41246b4"
      url="11/X23-81950_26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_ENTERPRISES_OEM_A64FRE_en-us.iso"
      ;;
    "win10arm64" | "win10arm64-enterprise" )
      size=4910370816
      sum="eb81ec03106683e53eb83cd8a5d7685f584c351f209f8acca07535bc1aa25dd5"
      url="10/en-us_windows_10_22h2_arm64.iso"
      ;;
    "win10arm64-ltsc" | "win10arm64-enterprise-ltsc" )
      size=4430471168
      sum="d265df49b30a1477d010c79185a7bc88591a1be4b3eb690c994bed828ea17c00"
      url="10/en-us_windows_10_iot_enterprise_ltsc_2021_arm64_dvd_e8d4fc46.iso"
      ;;
    "win10arm64-iot" | "win10arm64-enterprise-iot" )
      size=4430471168
      sum="d265df49b30a1477d010c79185a7bc88591a1be4b3eb690c994bed828ea17c00"
      url="10/en-us_windows_10_iot_enterprise_ltsc_2021_arm64_dvd_e8d4fc46.iso"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    * ) [ -n "$url" ] && echo "$host/$url";;
  esac

  return 0
}

getLink2() {

  # Fallbacks for users who cannot connect to the Microsoft servers

  local id="$1"
  local lang="$2"
  local ret="$3"
  local url=""
  local sum=""
  local size=""
  local host="https://dl.bobpony.com/windows"

  isCompatible && return 0
  [[ "${lang,,}" != "en" && "${lang,,}" != "en-us" ]] && return 0

  case "${id,,}" in
    "win11arm64" | "win11arm64-enterprise" )
      size=6755211264
      sum="bde2bcefe470bd19eb6cb810f38478dbd6809f04bac20c26ff27d4c9b864f662"
      url="11/en-us_windows_11_23h2_arm64.iso"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    * ) [ -n "$url" ] && echo "$host/$url";;
  esac

  return 0
}

getLink3() {

  local id="$1"
  local lang="$2"
  local ret="$3"
  local url=""
  local sum=""
  local size=""
  local host="https://archive.org/download"

  [[ "${id,,}" == "win11"* ]] && ! isCompatible && return 0
  [[ "${lang,,}" != "en" && "${lang,,}" != "en-us" ]] && return 0

  case "${id,,}" in
    "win11arm64" )
      size=5460387840
      sum="57d1dfb2c6690a99fe99226540333c6c97d3fd2b557a50dfe3d68c3f675ef2b0"
      url="Windows11_24H2_Arm64_ISO/Win11_24H2_English_Arm64.iso"
      ;;
    "win11arm64-enterprise" )
      size=6872444928
      sum="2bf0fd1d5abd267cd0ae8066fea200b3538e60c3e572428c0ec86d4716b61cb7"
      url="win11-23h2-en-fr/ARM64/SW_DVD9_Win_Pro_11_23H2_Arm64_English_Pro_Ent_EDU_N_MLF_X23-59519.ISO"
      ;;
    "win11arm64-ltsc" | "win11arm64-enterprise-ltsc" )
      size=5121449984
      sum="f8f068cdc90c894a55d8c8530db7c193234ba57bb11d33b71383839ac41246b4"
      url="Windows11LTSC/X23-81950_26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_ENTERPRISES_OEM_A64FRE_en-us.iso"
      ;;
    "win11arm64-iot" | "win11arm64-enterprise-iot" )
      size=5121449984
      sum="f8f068cdc90c894a55d8c8530db7c193234ba57bb11d33b71383839ac41246b4"
      url="Windows11LTSC/X23-81950_26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_ENTERPRISES_OEM_A64FRE_en-us.iso"
      ;;
    "win10arm64" | "win10arm64-enterprise" )
      size=5192060928
      sum="101079b911c8c3dd9c9a88499a16b930fbf00cbaf901761d8265bb3a8fcd9ea9"
      url="win-pro-10-22-h-2.15-arm-64-eng-intl-pro-ent-edu-n-mlf-x-23-67222/Win_Pro_10_22H2.15_Arm64_Eng_Intl_Pro_Ent_EDU_N_MLF_X23-67222.ISO"
      ;;
    "win10arm64-ltsc" | "win10arm64-enterprise-ltsc" )
      size=4430471168
      sum="d265df49b30a1477d010c79185a7bc88591a1be4b3eb690c994bed828ea17c00"
      url="windows-10-enterprise-ltsc-full-collection/en-us_windows_10_iot_enterprise_ltsc_2021_arm64_dvd_e8d4fc46.iso"
      ;;
    "win10arm64-iot" | "win10arm64-enterprise-iot" )
      size=4430471168
      sum="d265df49b30a1477d010c79185a7bc88591a1be4b3eb690c994bed828ea17c00"
      url="windows-10-enterprise-ltsc-full-collection/en-us_windows_10_iot_enterprise_ltsc_2021_arm64_dvd_e8d4fc46.iso"
      ;;
    "tiny11" )
      size=5554755584
      sum="5c5d45799e1664d81802d1d5a85b9e50c1dcf278e1d2e7e10e3328fc8dd4615c"
      url="tiny11_25H2/tiny11_25H2_Oct25_arm64.iso"
      ;;
    "core11" )
      size=3307509760
      sum="dbc533be2e3a679c548eb9e11b7827d0be9b7aea8d9fea8288fceba4965139e1"
      url="tiny11_25H2/tiny11core_25H2_Oct25_arm64.iso"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    * ) [ -n "$url" ] && echo "$host/$url" ;;
  esac

  return 0
}

getLink4() {

  local id="$1"
  local lang="$2"
  local ret="$3"
  local url=""
  local sum=""
  local size=""
  local host="https://archive.org/download"

  isCompatible && return 0
  [[ "${lang,,}" != "en" && "${lang,,}" != "en-us" ]] && return 0

  case "${id,,}" in
    "win11arm64" | "win11arm64-enterprise" )
      size=6872444928
      sum="2bf0fd1d5abd267cd0ae8066fea200b3538e60c3e572428c0ec86d4716b61cb7"
      url="win11-23h2-en-fr/ARM64/SW_DVD9_Win_Pro_11_23H2_Arm64_English_Pro_Ent_EDU_N_MLF_X23-59519.ISO"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    * ) [ -n "$url" ] && echo "$host/$url";;
  esac

  return 0
}

getValue() {

  local val=""
  local id="$2"
  local lang="$3"
  local type="$4"
  local func="getLink$1"

  if [ "$1" -gt 0 ] && [ "$1" -le "$MIRRORS" ]; then
    val=$($func "$id" "$lang" "$type")
  fi

  echo "$val"
  return 0
}

getLink() {

  getValue "$1" "$2" "$3" ""
}

getHash() {

  getValue "$1" "$2" "$3" "sum"
}

getSize() {

  getValue "$1" "$2" "$3" "size"
}

isMido() {

  local id="$1"
  local lang="$2"
  local sum

  disabled "${MIDO:-}" && return 1

  sum=$(getMido "$id" "en" "sum")
  [ -n "$sum" ] && return 0

  return 1
}

isESD() {

  local id="$1"
  local lang="$2"

  disabled "${ESD:-}" && return 1

  case "${id,,}" in
    "win11${PLATFORM,,}" | \
    "win10${PLATFORM,,}" | \
    "win11${PLATFORM,,}-enterprise" | \
    "win10${PLATFORM,,}-enterprise" )
      return 0
      ;;
  esac

  return 1
}

validVersion() {

  local id="$1"
  local lang="$2"
  local url i

  isMido "$id" "$lang" && return 0

  [[ "${id,,}" == *"-eval" ]] && id="${id::-5}"

  isESD "$id" "$lang" && return 0

  for ((i=1;i<=MIRRORS;i++)); do

    url=$(getLink "$i" "$id" "$lang")
    [ -n "$url" ] && return 0

  done

  return 1
}

isCompatible() {

  # ARMv8.0 cannot run Windows 11 builds 24H2 and up.
  if [[ "${ARCH,,}" == "arm64" ]] && ! hasFeature atomics; then
    return 1
  fi

  return 0
}

return 0
