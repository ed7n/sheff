# Adds `$1` filter `$2`.
SHF.addFilter() {
  local -n shfOfis=shfOf"${1:0:1}"s
  local shfStr
  EWS.arrStr shfStr shfOfos ':'
  (( ${#shfStr} )) && {
    shfOfis+=("${2}"'='"${shfStr}") || :
  } || shfOfis+=("${2}")
}

# Adds filter options `$1=$2 $3=$4...$n`.
SHF.addFilterOpts() {
  while (( ${#} )); do
    (( ${#2} )) && {
      shfOfos+=("${1}"'='"${2}") || :
    } || {
      shfOfos+=("${1}")
      break
    }
    shift 2
  done
}

# Adds `$1` writer options `-$2 $3 -$4 $5...-$n`.
SHF.addWriterOpts() {
  local shfAbr="${1:0:1}" shfPre
  shift
  while (( ${#} )); do
    (( ${#shfPre} )) && {
      shfPre= || :
    } || shfPre='-'
    EWS.strCatWrd shfOw"${shfAbr}" "${shfPre}""${1}"
    shift
  done
}

# Returns whether filter options are not empty.
SHF.hasFilterOpts() {
  (( ${#shfOfos[@]} ))
}

# Returns whether `$1` is to be trancoded.
SHF.hasTranscode() {
  local shfAbr="${1:0:1}"
  local -n shfOwi=shfOw"${shfAbr}"
  [ "${shfOwi:0:9}" == '-c:'"${shfAbr}"' copy' ] \
      || [ "${shfOwi:0:3}" == '-'"${shfAbr}"'n' ]
}

# Clears audio and video filters, options, and writers.
SHF.rubAvOpts() {
  unset shfOfas[@] shfOfvs[@] shfOpas shfOpvs
  declare -Ag shfOpas shfOpms shfOpvs
  shfOwa=
  shfOwv=
}

# Sets `$1` output options `-$2 $3 -$4 $5...-$n`.
SHF.setOutputOpts() {
  local -n shfOpis=shfOp"${1:0:1}"s
  shift
  while (( ${#} )); do
    shfOpis[${1}]="${2}"
    shift 2 || shift
  done
}

# Builds command to `$1`.
SHF.buildCmd() {
  [ "${1}" == 'shfOut' ] || local -n shfOut="${1}"
  local shfStr
  shfOut="${SHF_EXE}"
  EWS.strCatWrd "${!shfOut}" '-hide_banner'
  (( ${#shfOip} )) && {
    shfStr="${shfOip@Q}" || :
  } || shfStr='"${1}"'
  EWS.strCatWrd "${!shfOut}" '-i' "${shfStr}"
  SHF.buildCmdOpts "${!shfOut}" 'v'
  SHF.buildCmdOpts "${!shfOut}" 'a'
  shfStr=
  EWS.mapStr shfStr shfOpms ' -' ' '
  (( ${#shfStr} )) && EWS.strCatWrd "${!shfOut}" '-'"${shfStr}"
  (( ${#shfOop} )) && {
    shfStr="${shfOop@Q}" || :
  } || shfStr='"${2}"'
  EWS.strCatWrd "${!shfOut}" "${shfStr}"
}

# Builds `$2` filter, writer, and output options to `$1`.
SHF.buildCmdOpts() {
  local shfAbr="${2:0:1}"
  local -n shfOwi=shfOw"${shfAbr}"
  local shfStr
  EWS.arrStr shfStr shfOf"${shfAbr}"s ','
  (( ${#shfStr} )) && {
    EWS.strCatWrd "${1}" '-'"${shfAbr}"'f' "${shfStr}"
    shfStr=
  }
  EWS.strCatWrd "${1}" "${shfOwi}"
  EWS.mapStr shfStr shfOp"${shfAbr}"s ' -' ' '
  (( ${#shfStr} )) && EWS.strCatWrd "${1}" '-'"${shfStr}"
}

# Page: Build + Run.
SHF.doBuildAndRun() {
  local shfEdt shfRan
  SHF.buildCmd shfCmd
  echo -e 'Command:\n  '"${shfCmd}"
  while true; do
    echo -n '[r] Run'
    (( ${#shfRan} )) && echo -n ' Again'
    echo -e '\n[e] Edit'
    (( ${#shfEdt} )) && echo '[u] Undo Edits'
    echo -e '[s] Save As Script...\n[0] ≡ Menu'
    while true; do
      EWS.readAndTrim
      (( ${#REPLY} )) && {
        case "${REPLY}" in
          'e' )
            echo 'Edits will be lost upon returning to the main menu.
Edit Mode. [Enter] to save.'
            EWS.break
            read -eri "${shfCmd}" shfCmd
            EWS.break
            shfEdt='edt'
            shfRan='' ;;
          'r' )
            EWS.break
            eval "${shfCmd}"
            EWS.break
            shfRan='ran' ;;
          's' )
            SHF.doSaveAsScript ;;
          'u' )
            (( ${#shfEdt} )) && {
              shfPag=5
              return
            } || continue ;;
          '0' )
            shfPag=0
            return ;;
          * )
            continue ;;
        esac || :
      } || continue
      break
    done
  done
}

# Page: `$1` Encoder.
SHF.doEncoder() {
  local shfAbr="${1:0:1}"
  local -n shfOpts=SHF_WRITERS_"${shfAbr@U}" shfOwi=shfOw"${shfAbr}"
  echo 'Select '"${1}"' encoder, or blank to skip.'
  SHU.echoOpts "${!shfOpts}"
  echo -e '[c] copy\n[n] (None)\n[b] (Blank)\n[0] ≡ Menu'
  while true; do
    EWS.readAndTrim
    (( ${#REPLY} )) && {
      EWS.isInt "${REPLY}" && EWS.isWithin "${REPLY}" 1 ${#shfOpts[@]} && {
        shfOwi='-c:'"${shfAbr}"
        EWS.strCatWrd "${!shfOwi}" "${shfOpts[$(( --REPLY ))]}"
        SHM.do"${shfOpts[${REPLY}]@u}" || :
      } || case "${REPLY}" in
        'c' )
          shfOwi='-c:'"${shfAbr}"
          EWS.strCatWrd "${!shfOwi}" 'copy' ;;
        'n' )
          shfOwi='-'"${shfAbr}"'n' ;;
        'b' )
          shfOwi= ;;
        '0' )
          shfPag=0 ;;
        * )
          continue ;;
      esac
    }
    break
  done
}

# Page: `$1` Filters.
SHF.doFilters() {
  local shfAbr="${1:0:1}" shfStr
  local -n shfOfis=shfOf"${shfAbr}"s shfOpts=SHF_FILTERS_"${shfAbr@U}"
  SHF.hasTranscode "${shfAbr}" \
      && echo "${1@u}"' not to be transcoded. Filters will not apply.'
  while true; do
    echo 'Select '"${1}"' filter to add.'
    SHU.echoOpts "${!shfOpts}"
    echo -e '[l] (List)\n[p] (Pop)\n[c] (Clear)\n[0] ≡ Menu'
    while true; do
      EWS.readAndTrim
      (( ${#REPLY} )) && {
        EWS.isInt "${REPLY}" && EWS.isWithin "${REPLY}" 1 ${#shfOpts[@]} && {
          SHM.do"${shfOpts[$(( REPLY - 1 ))]@u}"
          unset shfOfos[@]
          break
        } || case "${REPLY}" in
          'l' )
            shfStr=
            EWS.arrStr shfStr "${!shfOfis}" $'\n< '
            (( ${#shfStr} )) && {
              EWS.echoBack "${shfStr}" || :
            } || echo 'Empty.' ;;
          'p' )
            (( ${#shfOfis[@]} )) && {
              EWS.echoBack "${shfOfis[-1]}"
              unset shfOfis[-1] || :
            } || echo 'Empty.' ;;
          'c' )
            unset shfOfis[@] ;;
          '0' )
            shfPag=0
            return ;;
        esac
      }
    done
  done
}

# Page: Input Path.
SHF.doInPath() {
  echo 'Enter input path, or blank to skip.'
  while true; do
    EWS.readAndTrim
    (( ${#REPLY} == 0 )) || {
      SHU.testInFile "${REPLY}" && {
        shfOip="${REPLY}"
        EWS.title "${shfOip##*/}" || :
      }
    } && break
  done
}

# Page: ≡ Menu.
SHF.doMenu() {
  shfPag=
  while true; do
    echo -e "${ews[name]}"' '"${ews[sign]}"'\n——'"${ews[desc]}"'\n
Select page.
[i]  Input Path
[t]  Preset
[ve] Video Encoder
[ae] Audio Encoder
[o]  Output Path
[r]  Build + Run
[vo] Video Options
[vf]     ~ Filters
[ao] Audio Options
[af]     ~ Filters
[mo] Main Options
[p]  Probe Input
[v]  Variables
[q]  Quit'
    while true; do
      EWS.readAndTrim
      (( ${#REPLY} )) && {
        EWS.isInt "${REPLY}" && EWS.isWithin "${REPLY}" 1 11 \
            && (( shfPag = REPLY )) || case "${REPLY}" in
          'p' | 'v' )
            EWS.break ;;&
          'p' )
            "${SHF_EXP}" -hide_banner "${shfOip}" ;;&
          'v' )
            declare -p shfOpas shfOpms shfOpvs shfOfas shfOfos shfOfvs shfCmd \
                shfOip shfOop shfOwa shfOwv shfPag IFS ;;&
          'p' | 'v' )
            EWS.break ;;&
          'p' )
            continue ;;
          'v' )
            break ;;
          'q' )
            EWS.exit "${EWS_SCES}" ;;
          * )
            shfPag="${SHF_K2P[${REPLY}]}"
            (( ${#shfPag} )) || continue ;;
        esac
        return
      }
    done
  done
}

# Page: `$1` Options.
SHF.doOptions() {
  local shfAbr="${1:0:1}" shfStr
  local -n shfOpis=shfOp"${shfAbr}"s shfOpts=SHF_OPTIONS_"${shfAbr@U}"
  SHF.hasTranscode "${shfAbr}" \
      && echo "${1@u}"' not to be transcoded. Options may not apply.'
  while true; do
    echo 'Select '"${1}"' option to set.'
    SHU.echoOpts "${!shfOpts}"
    echo -e '[l] (List)\n[u] (Unset...)\n[c] (Clear)\n[0] ≡ Menu'
    while true; do
      EWS.readAndTrim
      (( ${#REPLY} )) && {
        EWS.isInt "${REPLY}" && EWS.isWithin "${REPLY}" 1 ${#shfOpts[@]} && {
          SHM.do"${shfOpts[$(( REPLY - 1 ))]@u}"
          break
        } || case "${REPLY}" in
          'l' )
            shfStr=
            EWS.mapStr shfStr "${!shfOpis}" $'\n< -' ' '
            (( ${#shfStr} )) && {
              EWS.echoBack '-'"${shfStr}" || :
            } || echo 'Empty.' ;;
          'u' )
            (( ${#shfOpis[@]} )) && {
              SHF.doOptionsUnset "${@}"
              break
            } || echo 'Empty.' ;;
          'c' )
            unset shfOpis
            declare -Ag "${!shfOpis}" ;;
          '0' )
            shfPag=0
            return ;;
        esac
      }
    done
  done
}

# Page: Unset.
SHF.doOptionsUnset() {
  local shfStr
  local -n shfOpis=shfOp"${1:0:1}"s
  (( ${#shfOpis[@]} )) && {
    echo 'Enter '"${1}"' option to unset, or blank to return.'
    while (( ${#shfOpis[@]} )); do
      EWS.readAndTrim
      (( ${#REPLY} )) && {
        shfStr='-'"${REPLY}"
        EWS.strCatWrd shfStr "${shfOpis[${REPLY}]}"
        EWS.echoBack "${shfStr}"
        unset shfOpis[${REPLY}]
      } || return
    done
  }
  echo 'Empty.'
}

# Page: Output Path.
SHF.doOutPath() {
  echo 'Enter output path, or blank to skip.'
  SHU.readOutPathOrBlank
  (( ${#REPLY} )) && shfOop="${REPLY}"
}

# Page: Preset.
SHF.doPreset() {
  echo 'Presets replace all audio and video encoders, filters, and options.
Select preset, or blank for manual setting.'
  SHU.echoOpts SHF_PRESETS
  echo -e '[c] (Clear Only)\n[0] ≡ Menu'
  while true; do
    EWS.readAndTrim
    (( ${#REPLY} )) && {
      EWS.isInt "${REPLY}" && EWS.isWithin "${REPLY}" 1 ${#SHF_PRESETS[@]} && {
        SHF.rubAvOpts
        SHM.do"${SHF_PRESETS[$(( REPLY - 1 ))]@u}"
        shfPag=4 || :
      } || case "${REPLY}" in
        'c' )
          SHF.rubAvOpts ;;
        '0' )
          shfPag=0 ;;
        * )
          continue ;;
      esac
    }
    break
  done
}

# Page: Save As Script.
SHF.doSaveAsScript() {
  echo 'Enter script output path, or blank to return.'
  SHU.readOutPathOrBlank
  (( ${#REPLY} )) && {
    local shfCwd="$(pwd)"
    echo $'#!/usr/bin/env bash\n\ncd '"${shfCwd@Q}"'
'"${shfCmd}" > "${REPLY}" && echo 'Saved.'
  }
}

shopt -q 'extglob' || shopt -qs 'extglob' \
    || EWS.exit '`extglob` shell option can not be set.' "${EWS_FAIL}"
[[ "${1}" == ?(-)?(-)[Hh]?([Ee][Ll][Pp]) ]] && {
  echo -e 'Usage: [<input>]
You will start at either the Preset or Input Path page. Follow the prompts to
build your FFmpeg command. You can skip most prompts with a blank. You can break
the flow and jump to any page first by selecting ≡ Menu whenever possible. The
main menu is also the only page from which options and filters can be accessed.'
  exit "${EWS_SCES}"
}
declare -p SHF_FILTERS_A SHF_FILTERS_V SHF_OPTIONS_A SHF_OPTIONS_V SHF_PRESETS \
    SHF_WRITERS_A SHF_WRITERS_V &> /dev/null \
    || EWS.exit 'Bad mods.' "${EWS_FAIL}"
(( ${#1} )) && {
  SHU.testInFile "${1}" || EWS.exit "${EWS_FAIL}"
  shfOip="${1}"
  shfPag=2
  EWS.title "${shfOip##*/}"
} || {
  shfPag=1
  EWS.title
}
type "${SHF_EXE}" &> /dev/null || echo '`'"${SHF_EXE}"'` not found.
You can still save your command and run it later.'
echo -e 'Working directory:\n  '"$(pwd)"
(( ${#shfOip} )) && echo -e 'Input path:\n  '"${1}"
while true; do
  case "${shfPag}" in
    '0' )
      SHF.doMenu
      continue ;;
    '1' )
      SHF.doInPath ;;&
    '2' )
      SHF.doPreset ;;&
    '3' )
      SHF.doEncoder 'video' ;;&
    '4' )
      SHF.doEncoder 'audio' ;;&
    '5' )
      SHF.doOutPath ;;&
    '6' )
      SHF.doBuildAndRun ;;&
    '1' | '2' | '3' | '4' | '5' | '6' )
      (( shfPag && shfPag++ )) || SHF.doMenu ;;
    '7' )
      SHF.doOptions 'video' ;;&
    '8' )
      SHF.doFilters 'video' ;;&
    '9' )
      SHF.doOptions 'audio' ;;&
    '10' )
      SHF.doFilters 'audio' ;;&
    '11' )
      SHF.doOptions 'main' ;;&
    '7' | '8' | '9' | '10' | '11' )
      SHF.doMenu ;;
    * )
      echo 'Bad page.'
      SHF.doMenu ;;
  esac
done
