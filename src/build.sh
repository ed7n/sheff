#!/usr/bin/env bash

{
  declare -p ews || declare -A ews=([base]="${0%/*}" [exec]="${0}" \
      [name]='SheFF Builder' [sign]='by Brendon, 12/31/2022.')
} &> /dev/null

# Parts.
readonly -a SHB_MODS=(
  'sheff-head.sh' 'sheff-ews.sh' 'sheff-utils.sh' 'sheff-mods.sh'
  'sheff-main.sh'
)
# Output path.
readonly SHB_OUT="${ews[base]}"'/../release/sheff.sh'

# Separator.
readonly SHB_SEP='~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
# Working path.
readonly SHB_TMP="${SHB_OUT}"'-'"${RANDOM}"
# For use in iterations.
IFS=' '

SHB.die() {
  (( ${#} )) && echo "${@}" 1>&2
  exit 1
}

type 'rm' &> /dev/null || SHB.die '`rm` not found.'

SHB.app() {
  local shbItm="${1##*/}"
  echo '# '"${shbItm}""${SHB_SEP:0:-${#shbItm}}"'

'"$(< "${1}")"'
' >> "${2}"
}

SHB.test() {
  [ -e "${1}" ] || SHB.die "${1}"': Not found.'
  [ -f "${1}" ] || SHB.die "${1}"': Not a regular file.'
  [ -r "${1}" ] || SHB.die "${1}"': No read permission.'
}

echo -e "${ews[name]}"' '"${ews[sign]}"'\n\nWorking directory:\n  '"$(pwd)"'
Output path:\n  '"${SHB_OUT}"'\nWorking path:\n  '"${SHB_TMP}"
for shbItm in "${SHB_MODS[@]}"; do
  SHB.test "${ews[base]}"'/'"${shbItm}"
done
echo -e 'Will append '${#SHB_MODS[@]}' files.\nNow building.'
echo -e '#!/usr/bin/env bash\n' > "${SHB_TMP}" \
    && for shbMod in "${SHB_MODS[@]}"; do
  echo '  Appending `'"${shbMod}"'`.' \
      && SHB.app "${ews[base]}"'/'"${shbMod}" "${SHB_TMP}" \
      || SHB.die
done \
    && echo '  Replacing with `'"${SHB_OUT}"'`.' \
    && echo "$(< "${SHB_TMP}")" > "${SHB_OUT}" \
    && rm "${SHB_TMP}" \
    && echo 'Done.' \
    || SHB.die
