(( ${#EWS_COLS} )) || readonly EWS_COLS=80
(( ${#EWS_FAIL} )) || readonly EWS_FAIL=1
(( ${#EWS_SCES} )) || readonly EWS_SCES=0

EWS.arrStr() {
  [ "${1}" == 'ewsStr' ] || local -n ewsStr="${1}"
  [ "${2}" == 'ewsArr' ] || local -n ewsArr="${2}"
  local ewsHed='hed' IFS=' '
  for ewsItm in "${ewsArr[@]}"; do
    (( ${#ewsItm} )) && {
      (( ${#ewsHed} )) && {
        ewsHed=
        ewsStr+="${ewsItm}" || :
      } || ewsStr+="${3}""${ewsItm}"
    }
  done
}

EWS.break() {
  local ewsLen ewsOut=${?}
  (( ${#1} )) && {
    ewsLen="${1}" || :
  } || {
    (( COLUMNS )) && ewsLen="${COLUMNS}" || :
  } || ewsLen="${EWS_COLS}"
  eval printf '~%.s' "{1..${ewsLen}}"
  echo
  return "${ewsOut}"
}

EWS.count() {
  local ewsStp
  (( ${#3} )) && {
    ewsStp="${3}" || :
  } || ewsStp=1
  eval echo "{${1}..${2}..${ewsStp}}"
}

EWS.echoBack() {
  echo -e '< '"${@}"
}

EWS.echoRead() {
  echo -e '> '"${@}"
}

EWS.exit() {
  while true; do
    (( ${#} == 0 )) || [[ "${1}" == [0-9] ]] && {
      (( ${#ews[wait]} )) && read -s ews[nul]
      echo -en '\033]2;\007'
      (( ${#1} )) && exit "${1}"
      exit "${EWS_FAIL}"
    } || echo -e "${1}" 1>&2
    shift
  done
}

EWS.isInt() {
  (( ${#} )) || return
  while (( ${#} )); do
    [[ "${1}" == ?([+-])@(+(0)|[1-9]*([[:digit:]])|0[Xx]+([[:xdigit:]])|0+([1-7])) ]] \
        || return
    shift
  done
}

EWS.isWithin() {
  (( ${#1} && ${#2} && ${#3} )) && {
    EWS.isInt "${1}" "${2}" "${3}" && {
      (( ${1} <= ${3} && ${1} >= ${2} ))
      return
    } || [ "${1}" '<' "${3}" ] && [ "${1}" '>' "${2}" ] \
        || [ "${1}" == "${3}" ] || [ "${1}" == "${2}" ]
  }
}

EWS.mapStr() {
  [ "${1}" == 'ewsStr' ] || local -n ewsStr="${1}"
  [ "${2}" == 'ewsMap' ] || local -n ewsMap="${2}"
  local ewsHed='hed' IFS=' '
  for ewsKey in "${!ewsMap[@]}"; do
    (( ${#ewsHed} )) && {
      ewsHed=
      ewsStr+="${ewsKey}" || :
    } || ewsStr+="${3}""${ewsKey}"
    (( ${#ewsMap[${ewsKey}]} )) && ewsStr+="${4}""${ewsMap[${ewsKey}]}"
  done
}

EWS.readAndTrim() {
  read -erp '> ' REPLY
  EWS.strTrim REPLY
}

EWS.strCatWrd() {
  [ "${1}" == 'ewsStr' ] || local -n ewsStr="${1}"
  shift
  (( ${#} )) && {
    #(( ${#ewsStr} == 0 ))
    [ ! "${ewsStr:0:1}" ] || [ "${ewsStr: -1}" == ' ' ] && {
      ewsStr+="${@}" || :
    } || ewsStr+=' '"${@}"
  }
}

EWS.strTrim() {
  while (( ${#} )); do
    [ "${1}" == 'ewsStr' ] || local -n ewsStr="${1}"
    ewsStr="${ewsStr%+([[:space:]])}"
    ewsStr="${ewsStr#+([[:space:]])}"
    [ "${1}" == 'ewsStr' ] || unset -n ewsStr
    shift
  done
}

EWS.title() {
  local ewsSub
  (( ${#} )) && ewsSub="${@}"' - '
  echo -en '\033]2;'"${ewsSub}""${ews[name]}"'\007'
}
