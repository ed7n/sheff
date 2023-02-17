# Prints option array `$1`.
SHU.echoOpts() {
  [ "${1}" == 'sfuOpts' ] || local -n sfuOpts="${1}"
  local IFS=' '
  for sfuIdx in $(EWS.count 0 $(( ${#sfuOpts[@]} - 1 ))); do
    echo '['$(( sfuIdx + 1 ))'] '"${sfuOpts[${sfuIdx}]}"
  done
}

# Reads a boolean or blank.
SHU.readBoolOrBlank() {
  while true; do
    EWS.readAndTrim
    (( ${#REPLY} )) && {
      [[ "${REPLY}" == [Nn] ]] && {
        REPLY=
        break
      }
      [[ "${REPLY}" == [Jj] ]] && {
        REPLY='REPLY'
        break
      } || :
    } || return
    echo "'j'"' or '"'n'"'?'
  done
}

# Reads an integer labeled `$1` within `[$2, $3]`.
SHU.readInt() {
  echo 'Enter '"${1}"' ['"${2}"', '"${3}"'].'
  while true; do
    EWS.readAndTrim
    (( ${#REPLY} == 0 )) || {
      EWS.isInt "${REPLY}" && EWS.isWithin "${REPLY}" "${2}" "${3}"
    } && break
  done
}

# Reads option `$1` labeled `$2`.
SHU.readOpt() {
  [ "${1}" == 'sfuOpts' ] || local -n sfuOpts="${1}"
  echo 'Select '"${2}"'.'
  SHU.echoOpts "${!sfuOpts}"
  while true; do
    EWS.readAndTrim
    (( ${#REPLY} == 0 )) || {
      EWS.isInt "${REPLY}" && EWS.isWithin "${REPLY}" 1 ${#sfuOpts[@]} \
          && (( REPLY-- || 1 ))
    } && break
  done
}

# Reads an output path or blank.
SHU.readOutPathOrBlank() {
  local shfPar
  while true; do
    EWS.readAndTrim
    (( ${#REPLY} == 0 )) || {
      shfPar="${REPLY%/*}"
      [ "${shfPar}" == "${REPLY}" ] || {
        [ -e "${shfPar}" ] || {
          echo 'Parent not found.'
          continue
        }
        [ -d "${shfPar}" ] || {
          echo 'Parent not a directory.'
          continue
        }
      }
      [ -e "${REPLY}" ] && echo 'Exists.' || :
    } && break
  done
}

# Reads a time labeled `$1`.
SHU.readTime() {
  echo 'Enter '"${1}"'.'
  while true; do
    EWS.readAndTrim
    (( ${#REPLY} == 0 )) \
        || [[ "${REPLY}" == ?(-)?(?(?([[:digit:]])[[:digit:]]:)?([[:digit:]])[[:digit:]]:?([[:digit:]])[[:digit:]]?(.+([[:digit:]]))|+([[:digit:]])?(.+([[:digit:]]))?(s|ms|us)) ]] \
        && break
  done
}

# Tests input file `$1`.
SHU.testInFile() {
  (( ${#} )) || {
    echo 'No file.'
    return 1
  }
  [ -e "${1}" ] || {
    echo 'Not found.'
    return 1
  }
  [ -f "${1}" ] || {
    echo 'Not a regular file.'
    return 1
  }
  [ -r "${1}" ] || {
    echo 'No read permission.'
    return 1
  }
}
