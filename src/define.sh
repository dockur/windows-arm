#!/usr/bin/env bash
set -Eeuo pipefail

: "${KEY:=""}"
: "${WIDTH:=""}"
: "${HEIGHT:=""}"
: "${VERIFY:=""}"
: "${REGION:=""}"
: "${EDITION:=""}"
: "${MANUAL:=""}"
: "${REMOVE:=""}"
: "${VERSION:=""}"
: "${DETECTED:=""}"
: "${KEYBOARD:=""}"
: "${LANGUAGE:=""}"
: "${USERNAME:=""}"
: "${PASSWORD:=""}"

MIRRORS=2

parseVersion() {

  if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
    VERSION="${VERSION:1:-1}"
  fi

  [ -z "$VERSION" ] && VERSION="win11"

  local msg="is not available for ARM64 CPU's."

  case "${VERSION,,}" in
    "11" | "11p" | "win11" | "pro11" | "win11p" | "windows11" | "windows 11" )
      VERSION="win11arm64"
      ;;
    "11e" | "win11e" | "windows11e" | "windows 11e" )
      VERSION="win11arm64-enterprise-eval"
      ;;
    "11i" | "11iot" | "iot11" | "win11i" | "win11-iot" | "win11arm64-iot" | "win11arm64-enterprise-iot-eval" )
      VERSION="win11arm64-enterprise-ltsc-eval"
      [ -z "$DETECTED" ] && DETECTED="win11arm64-ltsc"
      ;;
    "11l" | "11ltsc" | "ltsc11" | "win11l" | "win11-ltsc" | "win11arm64-ltsc" | "win11arm64-enterprise-ltsc-eval" )
      VERSION="win11arm64-enterprise-ltsc-eval"
      [ -z "$DETECTED" ] && DETECTED="win11arm64-ltsc"
      ;;
    "10" | "10p" | "win10" | "pro10" | "win10p" | "windows10" | "windows 10" )
      VERSION="win10arm64"
      ;;
    "10e" | "win10e" | "windows10e" | "windows 10e" )
      VERSION="win10arm64-enterprise-eval"
      ;;
    "10i" | "10iot" | "iot10" | "win10i" | "win10-iot" | "win10arm64-iot" | "win10arm64-enterprise-iot-eval" )
      VERSION="win10arm64-enterprise-ltsc-eval"
      [ -z "$DETECTED" ] && DETECTED="win10arm64-ltsc"
      ;;
    "10l" | "10ltsc" | "ltsc10" | "win10l" | "win10-ltsc" | "win10arm64-ltsc" | "win10arm64-enterprise-ltsc-eval" )
      VERSION="win10arm64-enterprise-ltsc-eval"
      [ -z "$DETECTED" ] && DETECTED="win10arm64-ltsc"
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
      [ -z "$DETECTED" ] && DETECTED="win11arm64"
      ;;
    "core11" | "core 11" )
      VERSION="core11"
      [ -z "$DETECTED" ] && DETECTED="win11arm64"
      ;;
   "tiny10" | "tiny 10" )
      error "Tiny 10 $msg" && return 1
      ;;
  esac

  return 0
}

getLanguage() {

  local id="$1"
  local ret="$2"
  local lang=""
  local desc=""
  local short=""
  local culture=""

  case "${id,,}" in
    "ar" | "ar-"* )
      short="ar"
      lang="Arabic"
      desc="$lang"
      culture="ar-SA" ;;
    "bg" | "bg-"* )
      short="bg"
      lang="Bulgarian"
      desc="$lang"
      culture="bg-BG" ;;
    "cs" | "cs-"* | "cz" | "cz-"* )
      short="cs"
      lang="Czech"
      desc="$lang"
      culture="cs-CZ" ;;
    "da" | "da-"* | "dk" | "dk-"* )
      short="da"
      lang="Danish"
      desc="$lang"
      culture="da-DK" ;;
    "de" | "de-"* )
      short="de"
      lang="German"
      desc="$lang"
      culture="de-DE" ;;
    "el" | "el-"* | "gr" | "gr-"* )
      short="el"
      lang="Greek"
      desc="$lang"
      culture="el-GR" ;;
    "gb" | "en-gb" )
      short="en-gb"
      lang="English International"
      desc="English"
      culture="en-GB" ;;
    "en" | "en-"* )
      short="en"
      lang="English"
      desc="English"
      culture="en-US" ;;
    "mx" | "es-mx" )
      short="mx"
      lang="Spanish (Mexico)"
      desc="Spanish"
      culture="es-MX" ;;
    "es" | "es-"* )
      short="es"
      lang="Spanish"
      desc="$lang"
      culture="es-ES" ;;
    "et" | "et-"* )
      short="et"
      lang="Estonian"
      desc="$lang"
      culture="et-EE" ;;
    "fi" | "fi-"* )
      short="fi"
      lang="Finnish"
      desc="$lang"
      culture="fi-FI" ;;
    "ca" | "fr-ca" )
      short="ca"
      lang="French Canadian"
      desc="French"
      culture="fr-CA" ;;
    "fr" | "fr-"* )
      short="fr"
      lang="French"
      desc="$lang"
      culture="fr-FR" ;;
    "he" | "he-"* | "il" | "il-"* )
      short="he"
      lang="Hebrew"
      desc="$lang"
      culture="he-IL" ;;
    "hr" | "hr-"* | "cr" | "cr-"* )
      short="hr"
      lang="Croatian"
      desc="$lang"
      culture="hr-HR" ;;
    "hu" | "hu-"* )
      short="hu"
      lang="Hungarian"
      desc="$lang"
      culture="hu-HU" ;;
    "it" | "it-"* )
      short="it"
      lang="Italian"
      desc="$lang"
      culture="it-IT" ;;
    "ja" | "ja-"* | "jp" | "jp-"* )
      short="ja"
      lang="Japanese"
      desc="$lang"
      culture="ja-JP" ;;
    "ko" | "ko-"* | "kr" | "kr-"* )
      short="ko"
      lang="Korean"
      desc="$lang"
      culture="ko-KR" ;;
    "lt" | "lt-"* )
      short="lt"
      lang="Lithuanian"
      desc="$lang"
      culture="lt-LT" ;;
    "lv" | "lv-"* )
      short="lv"
      lang="Latvian"
      desc="$lang"
      culture="lv-LV" ;;
    "nb" | "nb-"* |"nn" | "nn-"* | "no" | "no-"* )
      short="no"
      lang="Norwegian"
      desc="$lang"
      culture="nb-NO" ;;
    "nl" | "nl-"* )
      short="nl"
      lang="Dutch"
      desc="$lang"
      culture="nl-NL" ;;
    "pl" | "pl-"* )
      short="pl"
      lang="Polish"
      desc="$lang"
      culture="pl-PL" ;;
    "br" | "pt-br" )
      short="pt"
      lang="Brazilian Portuguese"
      desc="Portuguese"
      culture="pt-BR" ;;
    "pt" | "pt-"* )
      short="pp"
      lang="Portuguese"
      desc="$lang"
      culture="pt-BR" ;;
    "ro" | "ro-"* )
      short="ro"
      lang="Romanian"
      desc="$lang"
      culture="ro-RO" ;;
    "ru" | "ru-"* )
      short="ru"
      lang="Russian"
      desc="$lang"
      culture="ru-RU" ;;
    "sk" | "sk-"* )
      short="sk"
      lang="Slovak"
      desc="$lang"
      culture="sk-SK" ;;
    "sl" | "sl-"* | "si" | "si-"* )
      short="sl"
      lang="Slovenian"
      desc="$lang"
      culture="sl-SI" ;;
    "sr" | "sr-"* )
      short="sr"
      lang="Serbian Latin"
      desc="Serbian"
      culture="sr-Latn-RS" ;;
    "sv" | "sv-"* | "se" | "se-"* )
      short="sv"
      lang="Swedish"
      desc="$lang"
      culture="sv-SE" ;;
    "th" | "th-"* )
      short="th"
      lang="Thai"
      desc="$lang"
      culture="th-TH" ;;
    "tr" | "tr-"* )
      short="tr"
      lang="Turkish"
      desc="$lang"
      culture="tr-TR" ;;
    "ua" | "ua-"* | "uk" | "uk-"* )
      short="uk"
      lang="Ukrainian"
      desc="$lang"
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
    "zh" | "zh-"* | "cn" | "cn-"* )
      short="cn"
      lang="Chinese (Simplified)"
      desc="Chinese"
      culture="zh-CN" ;;
  esac

  case "${ret,,}" in
    "desc" ) echo "$desc" ;;
    "name" ) echo "$lang" ;;
    "code" ) echo "$short" ;;
    "culture" ) echo "$culture" ;;
    *) echo "$desc";;
  esac

  return 0
}

parseLanguage() {

  REGION="${REGION//_/-/}"
  KEYBOARD="${KEYBOARD//_/-/}"
  LANGUAGE="${LANGUAGE//_/-/}"

  [ -z "$LANGUAGE" ] && LANGUAGE="en"

  case "${LANGUAGE,,}" in
    "arabic" | "arab" ) LANGUAGE="ar" ;;
    "bulgarian" | "bu" ) LANGUAGE="bg" ;;
    "chinese" | "cn" ) LANGUAGE="zh" ;;
    "croatian" | "cr" | "hrvatski" ) LANGUAGE="hr" ;;
    "czech" | "cz" | "cesky" ) LANGUAGE="cs" ;;
    "danish" | "dk" | "danske" ) LANGUAGE="da" ;;
    "dutch" | "nederlands" ) LANGUAGE="nl" ;;
    "english" | "gb" | "british" ) LANGUAGE="en" ;;
    "estonian" | "eesti" ) LANGUAGE="et" ;;
    "finnish" | "suomi" ) LANGUAGE="fi" ;;
    "french" | "français" | "francais" ) LANGUAGE="fr" ;;
    "german" | "deutsch" ) LANGUAGE="de" ;;
    "greek" | "gr" ) LANGUAGE="el" ;;
    "hebrew" | "il" ) LANGUAGE="he" ;;
    "hungarian" | "magyar" ) LANGUAGE="hu" ;;
    "italian" | "italiano" ) LANGUAGE="it" ;;
    "japanese" | "jp" ) LANGUAGE="ja" ;;
    "korean" | "kr" ) LANGUAGE="ko" ;;
    "latvian" | "latvijas" ) LANGUAGE="lv" ;;
    "lithuanian" | "lietuvos" ) LANGUAGE="lt" ;;
    "norwegian" | "no" | "nb" | "norsk" ) LANGUAGE="nn" ;;
    "polish" | "polski" ) LANGUAGE="pl" ;;
    "portuguese" | "pt" | "br" ) LANGUAGE="pt-br" ;;
    "português" | "portugues" ) LANGUAGE="pt-br" ;;
    "romanian" | "română" | "romana" ) LANGUAGE="ro" ;;
    "russian" | "ruski" ) LANGUAGE="ru" ;;
    "serbian" | "serbian latin" ) LANGUAGE="sr" ;;
    "slovak" | "slovenský" | "slovensky" ) LANGUAGE="sk" ;;
    "slovenian" | "si" | "slovenski" ) LANGUAGE="sl" ;;
    "spanish" | "espanol" | "español" ) LANGUAGE="es" ;;
    "swedish" | "se" | "svenska" ) LANGUAGE="sv" ;;
    "turkish" | "türk" | "turk" ) LANGUAGE="tr" ;;
    "thai" ) LANGUAGE="th" ;;
    "ukrainian" | "ua" ) LANGUAGE="uk" ;;
  esac

  local culture
  culture=$(getLanguage "$LANGUAGE" "culture")
  [ -n "$culture" ] && return 0

  error "Invalid LANGUAGE specified, value \"$LANGUAGE\" is not recognized!"
  return 1
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

printEdition() {

  local id="$1"
  local desc="$2"
  local result=""
  local edition=""

  result=$(printVersion "$id" "x")
  [[ "$result" == "x" ]] && echo "$desc" && return 0

  case "${id,,}" in
    *"-enterprise" )
      edition="Enterprise"
      ;;
    *"-iot" | *"-iot-eval" )
      edition="LTSC"
      ;;
    *"-ltsc" | *"-ltsc-eval" )
      edition="LTSC"
      ;;
    *"-enterprise-eval" )
      edition="Enterprise (Evaluation)"
      ;;
    "win10"* | "win11"* )
      edition="Pro"
      ;;
  esac

  [ -n "$edition" ] && result+=" $edition"

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
    *"_x64_"* | *"_x64."*)
      arch="x64"
      ;;
    *"_x86_"* | *"_x86."*)
      arch="x86"
      ;;
    *"_arm64_"* | *"_arm64."*)
      arch="arm64"
      ;;
  esac

  case "$file" in
    "tiny11core"* | "tiny11_core"* | "tiny_11_core"* )
      id="core11"
      ;;
    "tiny11"* | "tiny_11"* )
      id="tiny11"
      ;;
    "win10"*| "win_10"* | *"windows10"* | *"windows_10"* )
      id="win10${arch}"
      ;;
    "win11"* | "win_11"* | *"windows11"* | *"windows_11"* )
      id="win11${arch}"
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

getVersion() {

  local id
  local name="$1"
  local arch="$2"

  id=$(fromName "$name" "$arch")

  case "${id,,}" in
    "win10"* | "win11"* )
       case "${name,,}" in
          *" iot"* ) id="$id-ltsc" ;;
          *" ltsc"* ) id="$id-ltsc" ;;
          *" enterprise evaluation"* ) id="$id-enterprise-eval" ;;
          *" enterprise"* ) id="$id-enterprise" ;;
        esac
      ;;
  esac

  echo "$id"
  return 0
}

switchEdition() {

  local id="$1"

  [[ "${id,,}" == *"-eval" ]] && DETECTED="${id::-5}"

  return 0
}

getMido() {

  local id="$1"
  local lang="$2"
  local ret="$3"
  local url=""
  local sum=""
  local size=""

  [[ "${lang,,}" != "en" ]] && [[ "${lang,,}" != "en-us" ]] && return 0

  case "${id,,}" in
    "win11arm64" )
      size=5460387840
      sum="57d1dfb2c6690a99fe99226540333c6c97d3fd2b557a50dfe3d68c3f675ef2b0"
      ;;
    "win11arm64-enterprise-eval" )
      size=4295096320
      sum="dad633276073f14f3e0373ef7e787569e216d54942ce522b39451c8f2d38ad43"
      ;;
    "win11arm64-enterprise-ltsc-eval" )
      size=5042194432
      sum="3dcdba9c9c0aa0430d4332b60c9afcb3cd613d648a49cbba2d4ef7b5978f32e8"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    *) echo "$url";;
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

  [[ "${lang,,}" != "en" ]] && [[ "${lang,,}" != "en-us" ]] && return 0

  case "${id,,}" in
    "win11arm64" | "win11arm64-enterprise" | "win11arm64-enterprise-eval" )
      size=5219411968
      sum="dbd54452c3c20b4625f511dae3c3e057270448fb661232d4fa66279f59a63157"
      url="11/en-us_windows_11_24h2_arm64.iso"
      ;;
    "win11arm64-ltsc" | "win11arm64-enterprise-ltsc-eval" )
      size=5121449984
      sum="f8f068cdc90c894a55d8c8530db7c193234ba57bb11d33b71383839ac41246b4"
      url="11/X23-81950_26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_ENTERPRISES_OEM_A64FRE_en-us.iso"
      ;;
    "win10arm64" | "win10arm64-enterprise" | "win10arm64-enterprise-eval" )
      size=4689637376
      sum="7b43e64f4e3b961a83f9b70efa4b9d863bc5c348fe86d75917ac974116d17227"
      url="10/en-us_windows_10_22h2_arm64.iso"
      ;;
    "win10arm64-ltsc" | "win10arm64-enterprise-ltsc-eval" )
      size=4430471168
      sum="d265df49b30a1477d010c79185a7bc88591a1be4b3eb690c994bed828ea17c00"
      url="10/en-us_windows_10_iot_enterprise_ltsc_2021_arm64_dvd_e8d4fc46.iso"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    *) [ -n "$url" ] && echo "$host/$url";;
  esac

  return 0
}

getLink2() {

  local id="$1"
  local lang="$2"
  local ret="$3"
  local url=""
  local sum=""
  local size=""
  local host="https://archive.org/download"

  [[ "${lang,,}" != "en" ]] && [[ "${lang,,}" != "en-us" ]] && return 0

  case "${id,,}" in
    "tiny11" )
      size=4480499712
      sum="ec6056aa554c17290224af23e1b99961fe99606bb5ea9102d61838939c63325b"
      url="tiny11a64/tiny11a64%20r1.iso"
      ;;
    "core11" )
      size=3300327424
      sum="812dae6b5bf5215db63b61ae10d8f0ffd3aa8529a18d96e9ced53341e2c676ec"
      url="tiny11-core-arm64/tiny11%20core%20arm64.iso"
      ;;
    "win11arm64" )
      size=5460387840
      sum="57d1dfb2c6690a99fe99226540333c6c97d3fd2b557a50dfe3d68c3f675ef2b0"
      url="windows-11-24h2-arm64-iso/Win11_24H2_English_Arm64.iso"
      ;;
    "win11arm64-enterprise" | "win11arm64-enterprise-eval" )
      size=6872444928
      sum="2bf0fd1d5abd267cd0ae8066fea200b3538e60c3e572428c0ec86d4716b61cb7"
      url="win11-23h2-en-fr/ARM64/SW_DVD9_Win_Pro_11_23H2_Arm64_English_Pro_Ent_EDU_N_MLF_X23-59519.ISO"
      ;;
    "win11arm64-ltsc" | "win11arm64-enterprise-ltsc-eval" )
      size=5121449984
      sum="f8f068cdc90c894a55d8c8530db7c193234ba57bb11d33b71383839ac41246b4"
      url="Windows11LTSC/X23-81950_26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_ENTERPRISES_OEM_A64FRE_en-us.iso"
      ;;
    "win10arm64" | "win10arm64-enterprise" | "win10arm64-enterprise-eval" )
      size=5192060928
      sum="101079b911c8c3dd9c9a88499a16b930fbf00cbaf901761d8265bb3a8fcd9ea9"
      url="win-pro-10-22-h-2.15-arm-64-eng-intl-pro-ent-edu-n-mlf-x-23-67222/Win_Pro_10_22H2.15_Arm64_Eng_Intl_Pro_Ent_EDU_N_MLF_X23-67222.ISO"
      ;;
    "win10arm64-ltsc" | "win10arm64-enterprise-ltsc-eval" )
      size=4430471168
      sum="d265df49b30a1477d010c79185a7bc88591a1be4b3eb690c994bed828ea17c00"
      url="windows-10-enterprise-ltsc-full-collection/en-us_windows_10_iot_enterprise_ltsc_2021_arm64_dvd_e8d4fc46.iso"
      ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    *) [ -n "$url" ] && echo "$host/$url";;
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

  local url
  url=$(getValue "$1" "$2" "$3" "")

  echo "$url"
  return 0
}

getHash() {

  local sum
  sum=$(getValue "$1" "$2" "$3" "sum")

  echo "$sum"
  return 0
}

getSize() {

  local size
  size=$(getValue "$1" "$2" "$3" "size")

  echo "$size"
  return 0
}

isMido() {

  local id="$1"
  local lang="$2"
  local sum

  sum=$(getMido "$id" "en" "sum")
  [ -n "$sum" ] && return 0

  return 1
}

isESD() {

  local id="$1"
  local lang="$2"

  case "${id,,}" in
    "win11${PLATFORM,,}" | "win10${PLATFORM,,}" )
      return 0
      ;;
    "win11${PLATFORM,,}-enterprise" | "win11${PLATFORM,,}-enterprise-eval")
      return 0
      ;;
    "win10${PLATFORM,,}-enterprise" | "win10${PLATFORM,,}-enterprise-eval" )
      return 0
      ;;
  esac

  return 1
}

validVersion() {

  local id="$1"
  local lang="$2"
  local url

  isESD "$id" "$lang" && return 0
  isMido "$id" "$lang" && return 0

  for ((i=1;i<=MIRRORS;i++)); do

    url=$(getLink "$i" "$id" "$lang")
    [ -n "$url" ] && return 0

  done

  return 1
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

  local dest="$src/\$OEM\$/\$1/OEM"
  mkdir -p "$dest" || return 1
  cp -Lr "$folder/." "$dest" || return 1

  local file
  file=$(find "$dest" -maxdepth 1 -type f -iname install.bat -print -quit)
  [ -f "$file" ] && unix2dos -q "$file"

  return 0
}

detectLegacy() {
  return 1
}

prepareLegacy() {
  return 1
}

skipVersion() {
  return 1
}

setMachine() {
  return 0
}

return 0
