{
  declare -p ews || declare -A ews=([base]="${0%/*}" [exec]="${0}" \
      [name]='SheFF' [sign]='u0r1 by Brendon, 02/17/2023.' \
      [desc]='Interactive FFmpeg frontend. https://ed7n.github.io/sheff')
} &> /dev/null

# Executable.
readonly SHF_EXE='ffmpeg'

# Key to page.
readonly -A SHF_K2P=([i]=1 [p]=2 [ve]=3 [ae]=4 [o]=5 [r]=6 [vo]=7 [vf]=8 \
    [ao]=9 [af]=10 [m]=11)
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
