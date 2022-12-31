{
  declare -p ews || declare -A ews=([base]="${0%/*}" [exec]="${0}" \
      [name]='SheFF' [sign]='u0r0 by Brendon, 12/31/2022.' \
      [desc]='Interactive FFmpeg frontend. https://ed7n.github.io/sheff')
} &> /dev/null

# Executable.
readonly SHF_EXE='ffmpeg'

# Audio, main, and video output options.
declare -A shfOpas shfOpms shfOpvs
# Audio and video filters and filter options.
declare -a shfOfas shfOfos shfOfvs
# Command.
shfCmd=
# Input path.
shfOip=
# Output path.
shfOop=
# Audio writer and its options.
shfOwa=
# Video writer and its options.
shfOwv=
# Page.
shfPag=0
# For use in array iterations.
IFS=' '
