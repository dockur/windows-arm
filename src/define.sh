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
    "11" | "11p" | "win11" | "pro11" | "win11p" | "windows11" | "windows 11" )
      VERSION="win11arm64"
      ;;
    "11e" | "win11e" | "windows11e" | "windows 11e" )
      VERSION="win11arm64-enterprise-eval"
      ;;
    "ltsc11" | "11l" | "11ltsc" | "win11l" | "win11-ltsc" | "win11arm64-ltsc" | "win11arm64-enterprise-ltsc-eval" )
      VERSION="win11arm64-enterprise-ltsc-eval"
      [ -z "$DETECTED" ] && DETECTED="win11arm64-ltsc"
      ;;
    "10" | "10p" | "win10" | "pro10" | "win10p" | "windows10" | "windows 10" )
      VERSION="win10arm64"
      ;;
    "10e" | "win10e" | "windows10e" | "windows 10e" )
      VERSION="win10arm64-enterprise-eval"
      ;;
    "ltsc10" | "10l" | "10ltsc" | "win10l" | "win10-ltsc" | "win10arm64-ltsc" | "win10arm64-enterprise-ltsc-eval" )
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
    "win11arm64-enterprise-ltsc-eval" )
      size=4252764160
      sum="ccec358a760c3c581249f091ed42d04f37b2b99c347b7a58257c3cc272d7982c"
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
    "win11arm64" )
      case "${culture,,}" in
        "ar" | "ar-"* ) url="ar-sa_windows_11_consumer_editions_version_24h2_arm64_dvd_331e352e.iso" ;;
        "bg" | "bg-"* ) url="bg-bg_windows_11_consumer_editions_version_24h2_arm64_dvd_ad0f4159.iso" ;;
        "cs" | "cs-"* ) url="cs-cz_windows_11_consumer_editions_version_24h2_arm64_dvd_09e9a65d.iso" ;;
        "da" | "da-"* ) url="da-dk_windows_11_consumer_editions_version_24h2_arm64_dvd_cfc9f7d2.iso" ;;
        "de" | "de-"* ) url="de-de_windows_11_consumer_editions_version_24h2_arm64_dvd_77817e34.iso" ;;
        "el" | "el-"* ) url="el-gr_windows_11_consumer_editions_version_24h2_arm64_dvd_7ff49fe0.iso" ;;
        "gb" | "en-gb" ) url="en-gb_windows_11_consumer_editions_version_24h2_arm64_dvd_2fb276c5.iso" ;;
        "en" | "en-"* )
          size=5460387840
          sum="57d1dfb2c6690a99fe99226540333c6c97d3fd2b557a50dfe3d68c3f675ef2b0"
          url="en-us_windows_11_consumer_editions_version_24h2_arm64_dvd_4cc70bf6.iso" ;;
        "es" | "es-"* ) url="es-es_windows_11_consumer_editions_version_24h2_arm64_dvd_b0586d9e.iso" ;;
        "mx" | "es-mx" ) url="es-mx_windows_11_consumer_editions_version_24h2_arm64_dvd_29df5eac.iso" ;;        
        "et" | "et-"* ) url="et-ee_windows_11_consumer_editions_version_24h2_arm64_dvd_0895b4c2.iso" ;;
        "fi" | "fi-"* ) url="fi-fi_windows_11_consumer_editions_version_24h2_arm64_dvd_030941fb.iso" ;;
        "ca" | "fr-ca" ) url="fr-ca_windows_11_consumer_editions_version_24h2_arm64_dvd_08e2b30e.iso" ;;
        "fr" | "fr-"* ) url="fr-fr_windows_11_consumer_editions_version_24h2_arm64_dvd_f7d51069.iso" ;;
        "he" | "he-"* ) url="he-il_windows_11_consumer_editions_version_24h2_arm64_dvd_24838d6b.iso" ;;
        "hr" | "hr-"* ) url="hr-hr_windows_11_consumer_editions_version_24h2_arm64_dvd_260e2f8a.iso" ;;
        "hu" | "hu-"* ) url="hu-hu_windows_11_consumer_editions_version_24h2_arm64_dvd_981626d6.iso" ;;
        "it" | "it-"* ) url="it-it_windows_11_consumer_editions_version_24h2_arm64_dvd_30f0547d.iso" ;;
        "ja" | "ja-"* ) url="ja-jp_windows_11_consumer_editions_version_24h2_arm64_dvd_f5fc9b3e.iso" ;;
        "ko" | "ko-"* ) url="ko-kr_windows_11_consumer_editions_version_24h2_arm64_dvd_5dddc52e.iso" ;;
        "lt" | "lt-"* ) url="lt-lt_windows_11_consumer_editions_version_24h2_arm64_dvd_e83cfe4c.iso" ;;
        "lv" | "lv-"* ) url="lv-lv_windows_11_consumer_editions_version_24h2_arm64_dvd_0028b5e8.iso" ;;
        "nb" | "nb-"* ) url="nb-no_windows_11_consumer_editions_version_24h2_arm64_dvd_1df6aff1.iso" ;;
        "nl" | "nl-"* ) url="nl-nl_windows_11_consumer_editions_version_24h2_arm64_dvd_2a794237.iso" ;;
        "pl" | "pl-"* ) url="pl-pl_windows_11_consumer_editions_version_24h2_arm64_dvd_80af0fd7.iso" ;;
        "br" | "pt-br" ) url="pt-br_windows_11_consumer_editions_version_24h2_arm64_dvd_0648fb13.iso" ;;
        "pt" | "pt-"* ) url="pt-pt_windows_11_consumer_editions_version_24h2_arm64_dvd_223f3f3a.iso" ;;
        "ro" | "ro-"* ) url="ro-ro_windows_11_consumer_editions_version_24h2_arm64_dvd_78f3a92a.iso" ;;
        "ru" | "ru-"* ) url="ru-ru_windows_11_consumer_editions_version_24h2_arm64_dvd_8e4d44aa.iso" ;;
        "sk" | "sk-"* ) url="sk-sk_windows_11_consumer_editions_version_24h2_arm64_dvd_c8c147d6.iso" ;;
        "sl" | "sl-"* ) url="sl-si_windows_11_consumer_editions_version_24h2_arm64_dvd_f4e5671d.iso" ;;
        "sr" | "sr-"* ) url="sr-latn-rs_windows_11_consumer_editions_version_24h2_arm64_dvd_489179df.iso" ;;
        "sv" | "sv-"* ) url="sv-se_windows_11_consumer_editions_version_24h2_arm64_dvd_fa42c0cc.iso" ;;
        "th" | "th-"* ) url="th-th_windows_11_consumer_editions_version_24h2_arm64_dvd_abb88faa.iso" ;;
        "tr" | "tr-"* ) url="tr-tr_windows_11_consumer_editions_version_24h2_arm64_dvd_ea2494b5.iso" ;;
        "uk" | "uk-"* ) url="uk-ua_windows_11_consumer_editions_version_24h2_arm64_dvd_70fa6caf.iso" ;;
        "zh" | "zh-"* ) url="zh-cn_windows_11_consumer_editions_version_24h2_arm64_dvd_4b5c8070.iso" ;;
        "zh-hk" | "zh-tw" ) url="zh-tw_windows_11_consumer_editions_version_24h2_arm64_dvd_fa6b02d0.iso" ;;        
      esac
      ;;
    "win11arm64-enterprise" | "win11arm64-enterprise-eval" )
      case "${culture,,}" in
        "ar" | "ar-"* ) url="ar-sa_windows_11_business_editions_version_24h2_arm64_dvd_0b673385.iso" ;;
        "bg" | "bg-"* ) url="bg-bg_windows_11_business_editions_version_24h2_arm64_dvd_788c03e0.iso" ;;
        "cs" | "cs-"* ) url="cs-cz_windows_11_business_editions_version_24h2_arm64_dvd_1f7bc350.iso" ;;
        "da" | "da-"* ) url="da-dk_windows_11_business_editions_version_24h2_arm64_dvd_9d466587.iso" ;;
        "de" | "de-"* ) url="de-de_windows_11_business_editions_version_24h2_arm64_dvd_c2e28d02.iso" ;;
        "el" | "el-"* ) url="el-gr_windows_11_business_editions_version_24h2_arm64_dvd_549d89e0.iso" ;;
        "gb" | "en-gb" ) url="en-gb_windows_11_business_editions_version_24h2_arm64_dvd_4b053a98.iso" ;;
        "en" | "en-"* )
          size=5388951552
          sum="15ff94a99e89846c54316275f60ea697c9517e5dea7b3a963157a4c632524f72"
          url="en-us_windows_11_business_editions_version_24h2_arm64_dvd_ad92e9d8.iso" ;;
        "es" | "es-"* ) url="es-es_windows_11_business_editions_version_24h2_arm64_dvd_81ab0494.iso" ;;
        "mx" | "es-mx" ) url="es-mx_windows_11_business_editions_version_24h2_arm64_dvd_2f7a4f0e.iso" ;;        
        "et" | "et-"* ) url="et-ee_windows_11_business_editions_version_24h2_arm64_dvd_49e9e4b9.iso" ;;
        "fi" | "fi-"* ) url="fi-fi_windows_11_business_editions_version_24h2_arm64_dvd_18c415d6.iso" ;;
        "ca" | "fr-ca" ) url="fr-ca_windows_11_business_editions_version_24h2_arm64_dvd_9de095b9.iso" ;;
        "fr" | "fr-"* ) url="fr-fr_windows_11_business_editions_version_24h2_arm64_dvd_dadf21c7.iso" ;;
        "he" | "he-"* ) url="he-il_windows_11_business_editions_version_24h2_arm64_dvd_a836dc29.iso" ;;
        "hr" | "hr-"* ) url="hr-hr_windows_11_business_editions_version_24h2_arm64_dvd_8b68a3fd.iso" ;;
        "hu" | "hu-"* ) url="hu-hu_windows_11_business_editions_version_24h2_arm64_dvd_0e1fd665.iso" ;;
        "it" | "it-"* ) url="it-it_windows_11_business_editions_version_24h2_arm64_dvd_c4e7511f.iso" ;;
        "ja" | "ja-"* ) url="ja-jp_windows_11_business_editions_version_24h2_arm64_dvd_28e70c96.iso" ;;
        "ko" | "ko-"* ) url="ko-kr_windows_11_business_editions_version_24h2_arm64_dvd_739157b9.iso" ;;
        "lt" | "lt-"* ) url="lt-lt_windows_11_business_editions_version_24h2_arm64_dvd_896253e8.iso" ;;
        "lv" | "lv-"* ) url="lv-lv_windows_11_business_editions_version_24h2_arm64_dvd_e5fd8399.iso" ;;
        "nb" | "nb-"* ) url="nb-no_windows_11_business_editions_version_24h2_arm64_dvd_698e7791.iso" ;;
        "nl" | "nl-"* ) url="nl-nl_windows_11_business_editions_version_24h2_arm64_dvd_7e6e0919.iso" ;;
        "pl" | "pl-"* ) url="pl-pl_windows_11_business_editions_version_24h2_arm64_dvd_b297967a.iso" ;;
        "br" | "pt-br" ) url="pt-br_windows_11_business_editions_version_24h2_arm64_dvd_7011721a.iso" ;;
        "pt" | "pt-"* ) url="pt-pt_windows_11_business_editions_version_24h2_arm64_dvd_221e64a5.iso" ;;
        "ro" | "ro-"* ) url="ro-ro_windows_11_business_editions_version_24h2_arm64_dvd_82cbceb3.iso" ;;
        "ru" | "ru-"* ) url="ru-ru_windows_11_business_editions_version_24h2_arm64_dvd_6ab7f1a4.iso" ;;
        "sk" | "sk-"* ) url="sk-sk_windows_11_business_editions_version_24h2_arm64_dvd_04ce533b.iso" ;;
        "sl" | "sl-"* ) url="sl-si_windows_11_business_editions_version_24h2_arm64_dvd_dd345ed1.iso" ;;
        "sr" | "sr-"* ) url="sr-latn-rs_windows_11_business_editions_version_24h2_arm64_dvd_f2b86976.iso" ;;
        "sv" | "sv-"* ) url="sv-se_windows_11_business_editions_version_24h2_arm64_dvd_88f0e36f.iso" ;;
        "th" | "th-"* ) url="th-th_windows_11_business_editions_version_24h2_arm64_dvd_9c714026.iso" ;;
        "tr" | "tr-"* ) url="tr-tr_windows_11_business_editions_version_24h2_arm64_dvd_4da6f82d.iso" ;;
        "uk" | "uk-"* ) url="uk-ua_windows_11_business_editions_version_24h2_arm64_dvd_65304891.iso" ;;
        "zh" | "zh-"* ) url="zh-cn_windows_11_business_editions_version_24h2_arm64_dvd_9696a5e8.iso" ;;
        "zh-hk" | "zh-tw" ) url="zh-tw_windows_11_business_editions_version_24h2_arm64_dvd_99a82a4f.iso" ;;        
      esac
      ;;
    "win11arm64-ltsc" | "win11arm64-enterprise-ltsc-eval" )
      [[ "${lang,,}" != "en" ]] && [[ "${lang,,}" != "en-us" ]] && return 0
      size=5121449984
      sum="f8f068cdc90c894a55d8c8530db7c193234ba57bb11d33b71383839ac41246b4"
      url="en-us_windows_11_iot_enterprise_ltsc_2024_arm64_dvd_ec517836.iso"
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
  file=$(find "$dest" -maxdepth 1 -type f -iname install.bat | head -n 1)
  [ -f "$file" ] && unix2dos -q "$file"

  return 0
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
