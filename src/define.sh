#!/usr/bin/env bash
set -Eeuo pipefail

: "${XRES:=""}"
: "${YRES:=""}"
: "${VERIFY:=""}"
: "${REGION:=""}"
: "${MANUAL:=""}"
: "${REMOVE:=""}"
: "${VERSION:=""}"
: "${DETECTED:=""}"
: "${KEYBOARD:=""}"
: "${LANGUAGE:=""}"
: "${USERNAME:=""}"
: "${PASSWORD:=""}"

MIRRORS=2
PLATFORM="ARM64"

parseVersion() {

  if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
    VERSION="${VERSION:1:-1}"
  fi

  [ -z "$VERSION" ] && VERSION="win11"

  case "${VERSION,,}" in
    "11" | "11p" | "win11" | "win11p" | "windows11" | "windows 11" )
      VERSION="win11arm64"
      ;;
    "11e" | "win11e" | "windows11e" | "windows 11e" )
      VERSION="win11arm64-enterprise-eval"
      ;;
    "ltsc11" | "11ltsc" | "win11-ltsc" | "win11arm64-ltsc" | "win11arm64-enterprise-ltsc-eval" )
      VERSION="win11arm64-enterprise-ltsc-eval"
      [ -z "$DETECTED" ] && DETECTED="win11arm64-ltsc"
      ;;
    "10" | "10p" | "win10" | "win10p" | "windows10" | "windows 10" )
      VERSION="win10arm64"
      ;;
    "10e" | "win10e" | "windows10e" | "windows 10e" )
      VERSION="win10arm64-enterprise-eval"
      ;;
    "ltsc10" | "10ltsc" | "win10-ltsc" | "win10arm64-ltsc" | "win10arm64-enterprise-ltsc-eval" )
      VERSION="win10arm64-enterprise-ltsc-eval"
      [ -z "$DETECTED" ] && DETECTED="win10arm64-ltsc"
      ;;
  esac

  return 0
}

getLanguage() {

  local id="$1"
  local ret="$2"
  local lang=""
  local desc=""
  local culture=""

  case "${id,,}" in
    "ar" | "ar-"* )
      lang="Arabic"
      desc="$lang"
      culture="ar-SA" ;;
    "bg" | "bg-"* )
      lang="Bulgarian"
      desc="$lang"
      culture="bg-BG" ;;
    "cs" | "cs-"* | "cz" | "cz-"* )
      lang="Czech"
      desc="$lang"
      culture="cs-CZ" ;;
    "da" | "da-"* | "dk" | "dk-"* )
      lang="Danish"
      desc="$lang"
      culture="da-DK" ;;
    "de" | "de-"* )
      lang="German"
      desc="$lang"
      culture="de-DE" ;;
    "el" | "el-"* | "gr" | "gr-"* )
      lang="Greek"
      desc="$lang"
      culture="el-GR" ;;
    "gb" | "en-gb" )
      lang="English International"
      desc="English"
      culture="en-GB" ;;
    "en" | "en-"* )
      lang="English (United States)"
      desc="English"
      culture="en-US" ;;
    "mx" | "es-mx" )
      lang="Spanish (Mexico)"
      desc="Spanish"
      culture="es-MX" ;;
    "es" | "es-"* )
      lang="Spanish"
      desc="$lang"
      culture="es-ES" ;;
    "et" | "et-"* )
      lang="Estonian"
      desc="$lang"
      culture="et-EE" ;;
    "fi" | "fi-"* )
      lang="Finnish"
      desc="$lang"
      culture="fi-FI" ;;
    "ca" | "fr-ca" )
      lang="French Canadian"
      desc="French"
      culture="fr-CA" ;;
    "fr" | "fr-"* )
      lang="French"
      desc="$lang"
      culture="fr-FR" ;;
    "he" | "he-"* | "il" | "il-"* )
      lang="Hebrew"
      desc="$lang"
      culture="he-IL" ;;
    "hr" | "hr-"* | "cr" | "cr-"* )
      lang="Croatian"
      desc="$lang"
      culture="hr-HR" ;;
    "hu" | "hu-"* )
      lang="Hungarian"
      desc="$lang"
      culture="hu-HU" ;;
    "it" | "it-"* )
      lang="Italian"
      desc="$lang"
      culture="it-IT" ;;
    "ja" | "ja-"* | "jp" | "jp-"* )
      lang="Japanese"
      desc="$lang"
      culture="ja-JP" ;;
    "ko" | "ko-"* | "kr" | "kr-"* )
      lang="Korean"
      desc="$lang"
      culture="ko-KR" ;;
    "lt" | "lt-"* )
      lang="Lithuanian"
      desc="$lang"
      culture="lv-LV" ;;
    "lv" | "lv-"* )
      lang="Latvian"
      desc="$lang"
      culture="lt-LT" ;;
    "nb" | "nb-"* |"nn" | "nn-"* | "no" | "no-"* )
      lang="Norwegian"
      desc="$lang"
      culture="nb-NO" ;;
    "nl" | "nl-"* )
      lang="Dutch"
      desc="$lang"
      culture="nl-NL" ;;
    "pl" | "pl-"* )
      lang="Polish"
      desc="$lang"
      culture="pl-PL" ;;
    "br" | "pt-br" )
      lang="Brazilian Portuguese"
      desc="Portuguese"
      culture="pt-BR" ;;
    "pt" | "pt-"* )
      lang="Portuguese"
      desc="$lang"
      culture="pt-BR" ;;
    "ro" | "ro-"* )
      lang="Romanian"
      desc="$lang"
      culture="ro-RO" ;;
    "ru" | "ru-"* )
      lang="Russian"
      desc="$lang"
      culture="ru-RU" ;;
    "sk" | "sk-"* )
      lang="Slovak"
      desc="$lang"
      culture="sk-SK" ;;
    "sl" | "sl-"* | "si" | "si-"* )
      lang="Slovenian"
      desc="$lang"
      culture="sl-SI" ;;
    "sr" | "sr-"* )
      lang="Serbian Latin"
      desc="Serbian"
      culture="sr-Latn-RS" ;;
    "sv" | "sv-"* | "se" | "se-"* )
      lang="Swedish"
      desc="$lang"
      culture="sv-SE" ;;
    "th" | "th-"* )
      lang="Thai"
      desc="$lang"
      culture="th-TH" ;;
    "tr" | "tr-"* )
      lang="Turkish"
      desc="$lang"
      culture="tr-TR" ;;
    "ua" | "ua-"* | "uk" | "uk-"* )
      lang="Ukrainian"
      desc="$lang"
      culture="uk-UA" ;;
    "hk" | "zh-hk" | "cn-hk" )
      lang="Chinese Traditional"
      desc="Chinese HK"
      culture="zh-TW" ;;
    "tw" | "zh-tw" | "cn-tw" )
      lang="Chinese Traditional"
      desc="Chinese TW"
      culture="zh-TW" ;;
    "zh" | "zh-"* | "cn" | "cn-"* )
      lang="Chinese Simplified"
      desc="Chinese"
      culture="zh-CN" ;;
  esac

  case "${ret,,}" in
    "desc" ) echo "$desc" ;;
    "name" ) echo "$lang" ;;
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
      edition="IoT"
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

  case "${file// /_}" in
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

  case "${file// /_}" in
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
    *"windows 11"* ) id="win11${arch}" ;;
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
          *" iot"* ) id="$id-iot" ;;
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

  case "${id,,}" in
    "win11${PLATFORM,,}-enterprise-eval" )
      DETECTED="win11${PLATFORM,,}-enterprise"
      ;;
    "win10${PLATFORM,,}-enterprise-eval" )
      DETECTED="win10${PLATFORM,,}-enterprise"
      ;;
  esac

  return 0
}

getMido() {

  local id="$1"
  local lang="$2"
  local ret="$3"
  local sum=""
  local size=""

  [[ "${lang,,}" != "en" ]] && [[ "${lang,,}" != "en-us" ]] && return 0

  case "${id,,}" in
    "win11x64-enterprise-ltsc-eval" )
      size=5
      sum="xxx"
      ;;
    "win11x64-enterprise-iot-eval" )
      size=5
      sum="xxx"
       ;;
  esac

  case "${ret,,}" in
    "sum" ) echo "$sum" ;;
    "size" ) echo "$size" ;;
    *) echo "";;
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
  local host="https://drive.massgrave.dev"

  culture=$(getLanguage "$lang" "culture")

  case "${id,,}" in
    "win11arm64" | "win11arm64-enterprise" | "win11arm64-enterprise-eval" )
      case "${culture,,}" in
        "ar" | "ar-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Arabic_Pro_Ent_EDU_N_MLF_X23-68013.ISO" ;;
        "bg" | "bg-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Bulgarian_Pro_Ent_EDU_N_MLF_X23-68015.ISO" ;;
        "cs" | "cs-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Czech_Pro_Ent_EDU_N_MLF_X23-68019.ISO" ;;
        "da" | "da-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Danish_Pro_Ent_EDU_N_MLF_X23-68020.ISO" ;;
        "de" | "de-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_German_Pro_Ent_EDU_N_MLF_X23-68028.ISO" ;;
        "el" | "el-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Greek_Pro_Ent_EDU_N_MLF_X23-68029.ISO" ;;
        "gb" | "en-gb" ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Eng_Intl_Pro_Ent_EDU_N_MLF_X23-68022.ISO" ;;
        "en" | "en-"* )
          size=7010680832
          sum="3da19e8c8c418091081186e362fb53a1aa68dad255d1d28ace81e2c88c3f99ba"
          url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_English_Pro_Ent_EDU_N_MLF_X23-68023.ISO" ;;
        "mx" | "es-mx" ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Spanish_Latam_Pro_Ent_EDU_N_MLF_X23-68045.ISO" ;;
        "es" | "es-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Spanish_Pro_Ent_EDU_N_MLF_X23-68046.ISO" ;;
        "et" | "et-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Estonian_Pro_Ent_EDU_N_MLF_X23-68024.ISO" ;;
        "fi" | "fi-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Finnish_Pro_Ent_EDU_N_MLF_X23-68025.ISO" ;;
        "ca" | "fr-ca" ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_FrenchCanadian_Pro_Ent_EDU_N_MLF_X23-68027.ISO" ;;
        "fr" | "fr-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_French_Pro_Ent_EDU_N_MLF_X23-68026.ISO" ;;
        "he" | "he-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Hebrew_Pro_Ent_EDU_N_MLF_X23-68030.ISO" ;;
        "hr" | "hr-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Croatian_Pro_Ent_EDU_N_MLF_X23-68018.ISO" ;;
        "hu" | "hu-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Hungarian_Pro_Ent_EDU_N_MLF_X23-68031.ISO" ;;
        "it" | "it-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Italian_Pro_Ent_EDU_N_MLF_X23-68032.ISO" ;;
        "ja" | "ja-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Japanese_Pro_Ent_EDU_N_MLF_X23-68033.ISO" ;;
        "ko" | "ko-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Korean_Pro_Ent_EDU_N_MLF_X23-68034.ISO" ;;
        "lt" | "lt-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Lithuanian_Pro_Ent_EDU_N_MLF_X23-68036.ISO" ;;
        "lv" | "lv-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Latvian_Pro_Ent_EDU_N_MLF_X23-68035.ISO" ;;
        "nb" | "nb-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Norwegian_Pro_Ent_EDU_N_MLF_X23-68037.ISO" ;;
        "nl" | "nl-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Dutch_Pro_Ent_EDU_N_MLF_X23-68021.ISO" ;;
        "pl" | "pl-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Polish_Pro_Ent_EDU_N_MLF_X23-68038.ISO" ;;
        "br" | "pt-br" ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Brazilian_Pro_Ent_EDU_N_MLF_X23-68014.ISO" ;;
        "pt" | "pt-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Portuguese_Pro_Ent_EDU_N_MLF_X23-68039.ISO" ;;
        "ro" | "ro-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Romanian_Pro_Ent_EDU_N_MLF_X23-68040.ISO" ;;
        "ru" | "ru-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Russian_Pro_Ent_EDU_N_MLF_X23-68041.ISO" ;;
        "sk" | "sk-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Slovak_Pro_Ent_EDU_N_MLF_X23-68043.ISO" ;;
        "sl" | "sl-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Slovenian_Pro_Ent_EDU_N_MLF_X23-68044.ISO" ;;
        "sr" | "sr-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Serbian_Latin_Pro_Ent_EDU_N_MLF_X23-68042.ISO" ;;
        "sv" | "sv-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Swedish_Pro_Ent_EDU_N_MLF_X23-68047.ISO" ;;
        "th" | "th-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Thai_Pro_Ent_EDU_N_MLF_X23-68048.ISO" ;;
        "tr" | "tr-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Turkish_Pro_Ent_EDU_N_MLF_X23-68049.ISO" ;;
        "uk" | "uk-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_Ukrainian_Pro_Ent_EDU_N_MLF_X23-68050.ISO" ;;
        "zh-hk" | "zh-tw" ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_ChnTrad_Pro_Ent_EDU_N_MLF_X23-68017.ISO" ;;
        "zh" | "zh-"* ) url="SW_DVD9_Win_Pro_11_23H2.2_Arm64_ChnSimp_Pro_Ent_EDU_N_MLF_X23-68016.ISO" ;;
      esac
      ;;
    "win11arm64-ltsc" | "win11arm64-enterprise-ltsc-eval" )
      [[ "${lang,,}" != "en" ]] && [[ "${lang,,}" != "en-us" ]] && return 0
      size=5121449984
      sum="f8f068cdc90c894a55d8c8530db7c193234ba57bb11d33b71383839ac41246b4"
      url="X23-81950_26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_ENTERPRISES_OEM_A64FRE_en-us.iso"
      ;;
    "win10arm64" | "win10arm64-enterprise" | "win10arm64-enterprise-eval" )
      case "${culture,,}" in
        "ar" | "ar-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Arabic_Pro_Ent_EDU_N_MLF_X23-67213.ISO" ;;
        "bg" | "bg-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Bulgarian_Pro_Ent_EDU_N_MLF_X23-67215.ISO" ;;
        "cs" | "cs-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Czech_Pro_Ent_EDU_N_MLF_X23-67219.ISO" ;;
        "da" | "da-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Danish_Pro_Ent_EDU_N_MLF_X23-67220.ISO" ;;
        "de" | "de-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_German_Pro_Ent_EDU_N_MLF_X23-67228.ISO" ;;
        "el" | "el-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Greek_Pro_Ent_EDU_N_MLF_X23-67229.ISO" ;;
        "gb" | "en-gb" ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Eng_Intl_Pro_Ent_EDU_N_MLF_X23-67222.ISO" ;;
        "en" | "en-"* )
          size=5190453248
          sum="bd96b342193f81c0a2e6595d8d8b8dc01dbf789d19211699f6299fec7b712197"
          url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_English_Pro_Ent_EDU_N_MLF_X23-67223.ISO" ;;
        "mx" | "es-mx" ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Spanish_Latam_Pro_Ent_EDU_N_MLF_X23-67245.ISO" ;;
        "es" | "es-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Spanish_Pro_Ent_EDU_N_MLF_X23-67246.ISO" ;;
        "et" | "et-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Estonian_Pro_Ent_EDU_N_MLF_X23-67224.ISO" ;;
        "fi" | "fi-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Finnish_Pro_Ent_EDU_N_MLF_X23-67225.ISO" ;;
        "ca" | "fr-ca" ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_FrenchCanadian_Pro_Ent_EDU_N_MLF_X23-67227.ISO" ;;
        "fr" | "fr-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_French_Pro_Ent_EDU_N_MLF_X23-67226.ISO" ;;
        "he" | "he-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Hebrew_Pro_Ent_EDU_N_MLF_X23-67230.ISO" ;;
        "hr" | "hr-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Croatian_Pro_Ent_EDU_N_MLF_X23-67218.ISO" ;;
        "hu" | "hu-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Hungarian_Pro_Ent_EDU_N_MLF_X23-67231.ISO" ;;
        "it" | "it-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Italian_Pro_Ent_EDU_N_MLF_X23-67232.ISO" ;;
        "ja" | "ja-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Japanese_Pro_Ent_EDU_N_MLF_X23-67233.ISO" ;;
        "ko" | "ko-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Korean_Pro_Ent_EDU_N_MLF_X23-67234.ISO" ;;
        "lt" | "lt-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Lithuanian_Pro_Ent_EDU_N_MLF_X23-67236.ISO" ;;
        "lv" | "lv-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Latvian_Pro_Ent_EDU_N_MLF_X23-67235.ISO" ;;
        "nb" | "nb-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Norwegian_Pro_Ent_EDU_N_MLF_X23-67237.ISO" ;;
        "nl" | "nl-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Dutch_Pro_Ent_EDU_N_MLF_X23-67221.ISO" ;;
        "pl" | "pl-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Polish_Pro_Ent_EDU_N_MLF_X23-67238.ISO" ;;
        "br" | "pt-br" ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Brazilian_Pro_Ent_EDU_N_MLF_X23-67214.ISO" ;;
        "pt" | "pt-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Portuguese_Pro_Ent_EDU_N_MLF_X23-67239.ISO" ;;
        "ro" | "ro-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Romanian_Pro_Ent_EDU_N_MLF_X23-67240.ISO" ;;
        "ru" | "ru-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Russian_Pro_Ent_EDU_N_MLF_X23-67241.ISO" ;;
        "sk" | "sk-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Slovak_Pro_Ent_EDU_N_MLF_X23-67243.ISO" ;;
        "sl" | "sl-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Slovenian_Pro_Ent_EDU_N_MLF_X23-67244.ISO" ;;
        "sr" | "sr-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Serbian_Latin_Pro_Ent_EDU_N_MLF_X23-67242.ISO" ;;
        "sv" | "sv-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Swedish_Pro_Ent_EDU_N_MLF_X23-67247.ISO" ;;
        "th" | "th-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Thai_Pro_Ent_EDU_N_MLF_X23-67248.ISO" ;;
        "tr" | "tr-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Turkish_Pro_Ent_EDU_N_MLF_X23-67249.ISO" ;;
        "uk" | "uk-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_Ukrainian_Pro_Ent_EDU_N_MLF_X23-67250.ISO" ;;
        "zh-hk" | "zh-tw" ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_ChnTrad_Pro_Ent_EDU_N_MLF_X23-67217.ISO" ;;
        "zh" | "zh-"* ) url="SW_DVD9_Win_Pro_10_22H2.15_Arm64_ChnSimp_Pro_Ent_EDU_N_MLF_X23-67216.ISO" ;;
      esac
      ;;
    "win10arm64-ltsc" | "win10arm64-enterprise-ltsc-eval" )
      [[ "${lang,,}" != "en" ]] && [[ "${lang,,}" != "en-us" ]] && return 0
      size=4430471168
      sum="d265df49b30a1477d010c79185a7bc88591a1be4b3eb690c994bed828ea17c00"
      url="en-us_windows_10_iot_enterprise_ltsc_2021_arm64_dvd_e8d4fc46.iso"
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
      size=6326812672
      sum="464c75909b9c37864e144886445a2faa67ac86f0845a68cca3f017b97f810e8d"
      url="11/en-us_windows_11_23h2_arm64.iso"
      ;;
    "win11arm64-ltsc" | "win11arm64-enterprise-ltsc-eval" )
      [[ "${lang,,}" != "en" ]] && [[ "${lang,,}" != "en-us" ]] && return 0
      size=5121449984
      sum="f8f068cdc90c894a55d8c8530db7c193234ba57bb11d33b71383839ac41246b4"
      url="11/X23-81950_26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_ENTERPRISES_OEM_A64FRE_en-us.iso"
      ;;
    "win10arm64" | "win10arm64-enterprise" | "win10arm64-enterprise-eval" )
      size=4846794752
      sum="6d2688f95fa1d359d68ed0c38c3f38de7b3713c893410e15be9d1e706a4a58c7"
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

migrateFiles() {
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
