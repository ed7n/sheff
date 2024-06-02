#!/usr/bin/env bash

# sheff-head.sh~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

{
  declare -p ews || declare -A ews=([base]="${0%/*}" [exec]="${0}" \
      [name]='SheFF' [sign]='u0r4 by Brendon, 06/02/2024.' \
      [desc]='Interactive FFmpeg frontend. https://ed7n.github.io/sheff')
} &> /dev/null

# Executable.
readonly SHF_EXE='ffmpeg'
# Prober executable
readonly SHF_EXP='ffprobe'

# Key to page.
readonly -A SHF_K2P=([i]=1 [t]=2 [ve]=3 [ae]=4 [o]=5 [r]=6 [vo]=7 [vf]=8 \
    [ao]=9 [af]=10 [mo]=11)
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
# Last page.
shfPal=0
# For use in array iterations.
IFS=' '

# sheff-ews.sh~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
  read -ep '> ' REPLY
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

# sheff-utils.sh~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

# sheff-mods.sh~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

readonly -a SHF_FILTERS_A=(
  'aresample' 'lowpass' 'volume' 'mono'
)
readonly -a SHF_FILTERS_V=(
  'fps' 'hqdn3d' 'nlmeans' 'scale' 'yadif'
)
readonly -a SHF_OPTIONS_A=(
  'ac'
)
readonly -a SHF_OPTIONS_M=(
  'fs' 'pass' 'ss' 't' 'to' 'faststart'
)
readonly -a SHF_OPTIONS_V=(
  'aspect' 'display' 'g' 'noautorotate'
)
readonly -a SHF_PRESETS=(
  'web-hd' 'web-sd' 'ntsc-dvd' 'ntsc-vcd' 'ntsc-svcd' 'wav'
)
readonly -a SHF_WRITERS_A=(
  'aac' 'flac' 'libmp3lame' 'libopus' 'libtwolame' 'libvorbis'
)
readonly -a SHF_WRITERS_V=(
  'ffv1' 'mjpeg' 'libsvtav1' 'libtheora' 'libvpx' 'libvpx-vp9' 'libx264' \
  'libx265' 'libxvid'
)
readonly -a SHM_ARESAMPLE_DITHER=(
  'rectangular' 'triangular' 'triangular_hp' 'modified_e_weighted' 'shibata'
)
readonly -a SHM_ARESAMPLE_MATRIX=(
  'dolby' 'dplii'
)
readonly -a SHM_FMT_SAMPLE=(
  'u8p' 's16p' 's32p' 'fltp' 'dblp'
)
readonly -a SHM_FPS_ROUND=(
  'zero' 'inf' 'down' 'up' 'near'
)
readonly -a SHM_SCALE_KEEPASPECT=(
  'decrease' 'increase'
)
readonly -a SHM_SCALE_INTERPOLATION=(
  'mitchell' 'bilinear' 'bicubic' 'neighbor'
)
readonly -a SHM_VP8_DEADLINE=(
  'good' 'realtime'
)
readonly -a SHM_WISEMAN_V=(
  'cmp' 'rd' 'dct' 'faan' 'mbcmp' 'rd' 'mbd' 'rd' 'precmp' 'rd' 'subcmp' 'rd'
  'trellis' 2
)
readonly -a SHM_X264_PRESET=(
  'ultrafast' 'medium' 'slow' 'slower' 'veryslow' 'placebo'
)
readonly -a SHM_X264_PROFILE=(
  'baseline' 'main' 'high' 'high10' 'high422' 'high444'
)
readonly -a SHM_YADIF_DEINT=(
  'all' 'interlaced'
)
readonly -a SHM_YADIF_MODE=(
  'send_frame' 'send_field'
)
readonly -a SHM_YADIF_PARITY=(
  'tff' 'bff' 'auto'
)

SHM.doAac() {
  SHM.doBitrate 'audio' 1 512
}

SHM.doAc() {
  SHU.readInt 'channel count' 1 255
  (( ${#REPLY} )) && SHF.setOutputOpts 'a' 'ac' "${REPLY}"
}

SHM.doAresample() {
  SHU.readInt 'sample rate in Hz' 1 48000
  (( ${#REPLY} )) && {
    SHF.addFilterOpts 'out_sample_rate' "${REPLY}"
    echo 'Simulate nearest neighbor?'
    SHU.readBoolOrBlank
    (( ${#REPLY} )) && {
      SHF.addFilterOpts 'filter_size' '0' 'phase_shift' '0'
      EWS.echoRead 'filter_size=0:phase_shift=0' || :
    } || {
      SHF.addFilterOpts 'resampler' 'soxr'
      EWS.echoRead 'resampler=soxr'
      SHU.readInt 'SoXR precision in bits' 15 33
      (( ${#REPLY} )) && SHF.addFilterOpts 'precision' "${REPLY}"
    }
  }
  SHU.readOpt SHM_FMT_SAMPLE 'sample format'
  (( ${#REPLY} )) && {
    SHF.addFilterOpts 'out_sample_fmt' "${SHM_FMT_SAMPLE[${REPLY}]}"
    SHU.readOpt SHM_ARESAMPLE_DITHER 'dither method'
    (( ${#REPLY} )) \
        && SHF.addFilterOpts 'dither_method' "${SHM_ARESAMPLE_DITHER[${REPLY}]}"
  }
  SHU.readOpt SHM_ARESAMPLE_MATRIX 'matrixed stereo encoding'
  (( ${#REPLY} )) && {
    SHF.addFilterOpts 'matrix_encoding' "${SHM_ARESAMPLE_MATRIX[${REPLY}]}"
    SHF.setOutputOpts 'a' 'ac' 2
    EWS.echoRead '-ac 2'
  }
  SHF.hasFilterOpts && SHF.addFilter 'a' 'aresample'
}

SHM.doAspect() {
  local shmHet shmWid
  SHU.readInt 'width factor' 1 100
  shmWid="${REPLY}"
  SHU.readInt 'height factor' 1 100
  (( ${#REPLY} )) && {
    shmHet="${REPLY}"
    (( ${#shmWid} )) || shmWid=1 || :
  } || {
    (( ${#shmWid} )) && {
      shmHet=1 || :
    } || return
  }
  SHF.setOutputOpts 'v' 'aspect' "${shmWid}"':'"${shmHet}"
}

SHM.doBitrate() {
  local shmAbr="${1:0:1}"
  SHU.readInt "${1}"' bitrate in kb/s' "${2}" "${3}"
  (( ${#REPLY} )) && SHF.addWriterOpts "${shmAbr}" 'b:'"${shmAbr}" "${REPLY}"'k'
}

SHM.doDisplay() {
  SHU.readInt 'CCW rotation in degrees' 0 359
  (( ${#REPLY} )) && SHF.setOutputOpts 'v' 'display_rotation' "${REPLY}"
  echo 'Flip horizontally?'
  SHU.readBoolOrBlank
  (( ${#REPLY} )) && SHF.setOutputOpts 'v' 'display_hflip'
  echo 'Flip vertically?'
  SHU.readBoolOrBlank
  (( ${#REPLY} )) && SHF.setOutputOpts 'v' 'display_vflip'
}

SHM.doFaststart() {
  SHF.setOutputOpts 'm' 'movflags' 'faststart'
}

SHM.doFfv1() {
  local shmCrc
  echo 'Add CRC information to each slice?'
  SHU.readBoolOrBlank
  (( ${#REPLY} )) && {
    shmCrc=1 || :
  } || shmCrc=0
  SHF.addWriterOpts 'v' 'slicecrc' "${shmCrc}"
}

SHM.doFlac() {
  SHU.readInt 'compression level' 0 12
  (( ${#REPLY} )) && SHF.addWriterOpts 'a' 'compression_level' "${REPLY}"
}

SHM.doFps() {
  SHU.readInt 'framerate in f/s' 1 200
  (( ${#REPLY} )) && {
    SHF.addFilterOpts 'fps' "${REPLY}"
    SHU.readOpt SHM_FPS_ROUND 'rounding method'
    (( ${#REPLY} )) && SHF.addFilterOpts 'round' "${SHM_FPS_ROUND[${REPLY}]}"
    SHF.addFilter 'v' 'fps'
  }
}

SHM.doFs() {
  SHU.readInt 'file size limit in kB' 1 0x40000000
  (( ${#REPLY} )) && SHF.setOutputOpts 'm' 'fs' $(( REPLY * 1024 ))
}

SHM.doG() {
  SHU.readInt 'GOP size' 0 0x7fffffff
  (( ${#REPLY} )) && SHF.setOutputOpts 'v' 'g' "${REPLY}"
}

SHM.doHqdn3d() {
  SHF.addFilter 'v' 'hqdn3d'
}

SHM.doLibmp3lame() {
  SHM.doQuality 'audio' 0 9
  SHF.addWriterOpts 'a' 'compression_level' 0
  EWS.echoRead '-compression_level 0'
}

SHM.doLibopus() {
  SHM.doBitrate 'audio' 6 510
}

SHM.doLibsvtav1() {
  SHU.readInt 'constant rate factor' 0 63
  (( ${#REPLY} )) && SHF.addWriterOpts 'v' 'crf' "${REPLY}"
  SHU.readInt 'encoding speed' 0 13
  (( ${#REPLY} )) && SHF.addWriterOpts 'v' 'preset' "${REPLY}"
  SHU.readInt 'film grain synthesis level' 1 50
  (( ${#REPLY} )) \
      && SHF.addWriterOpts 'v' 'svtav1-params film-grain='"${REPLY}"
}

SHM.doLibtheora() {
  SHM.doQuality 'video' 1 10
  SHM.doWiseman
}

SHM.doLibtwolame() {
  SHM.doBitrate 'audio' 32 384
  SHF.addWriterOpts 'a' 'psymodel' 4
  EWS.echoRead '-psymodel 4'
}

SHM.doLibvpx() {
  SHU.readInt 'constrained quality' 0 63
  (( ${#REPLY} )) && SHF.addWriterOpts 'v' 'crf' "${REPLY}"
  SHU.readOpt SHM_VP8_DEADLINE 'deadline'
  (( ${#REPLY} )) \
      && SHF.addWriterOpts 'v' 'deadline' "${SHM_VP8_DEADLINE[${REPLY}]}"
  SHU.readInt 'quality-over-speed ratio modifier' -16 16
  (( ${#REPLY} )) && SHF.addWriterOpts 'v' 'cpu-used' "${REPLY}"
}

SHM.doLibvpx-vp9() {
  echo 'Encode losslessly?'
  SHU.readBoolOrBlank
  (( ${#REPLY} )) && {
    SHF.addWriterOpts 'v' 'lossless' 1 || :
  } || {
    SHU.readInt 'constant quality' 0 63
    (( ${#REPLY} )) && {
      SHF.addWriterOpts 'v' 'crf' "${REPLY}"
      SHF.addWriterOpts 'v' 'b:v' 0
      EWS.echoRead '-b:v 0'
    }
  }
  SHU.readOpt SHM_VP8_DEADLINE 'deadline'
  (( ${#REPLY} )) \
      && SHF.addWriterOpts 'v' 'deadline' "${SHM_VP8_DEADLINE[${REPLY}]}"
  SHU.readInt 'quality-over-speed ratio modifier' -16 16
  (( ${#REPLY} )) && SHF.addWriterOpts 'v' 'cpu-used' "${REPLY}"
}

SHM.doLibvorbis() {
  SHM.doQuality 'audio' -1 10
}

SHM.doLibx264() {
  echo 'Encode in RGB?'
  SHU.readBoolOrBlank
  (( ${#REPLY} )) && shfOwv+='rgb'
  SHU.readInt 'constant rate factor' 0 63
  (( ${#REPLY} )) && SHF.addWriterOpts 'v' 'crf' "${REPLY}"
  SHU.readOpt SHM_X264_PRESET 'preset'
  (( ${#REPLY} )) \
      && SHF.addWriterOpts 'v' 'preset' "${SHM_X264_PRESET[${REPLY}]}"
  SHU.readOpt SHM_X264_PROFILE 'profile'
  (( ${#REPLY} )) \
      && SHF.addWriterOpts 'v' 'profile:v' "${SHM_X264_PROFILE[${REPLY}]}"
}

SHM.doLibx265() {
  echo 'Encode losslessly?'
  SHU.readBoolOrBlank
  (( ${#REPLY} )) && {
    SHF.addWriterOpts 'v' 'x265-params' 'lossless='"${REPLY}" || :
  } || {
    SHU.readInt 'constant rate factor' 0 51
    (( ${#REPLY} )) && SHF.addWriterOpts 'v' 'crf' "${REPLY}"
  }
  SHU.readOpt SHM_X264_PRESET 'preset'
  (( ${#REPLY} )) \
      && SHF.addWriterOpts 'v' 'preset' "${SHM_X264_PRESET[${REPLY}]}"
}

SHM.doLibxvid() {
  SHM.doQuality 'video' 1 31
  SHM.doWiseman
  (( ${#REPLY} )) && {
    SHF.addWriterOpts 'v' 'flags' '+mv4+aic'
    EWS.echoRead '-flags +mv4+aic'
  }
}

SHM.doLowpass() {
  SHU.readInt 'cutoff in Hz' 1 20000
  (( ${#REPLY} )) && SHF.addFilterOpts 'f' "${REPLY}"
  SHU.readInt 'poles count' 1 2
  (( ${#REPLY} )) && SHF.addFilterOpts 'p' "${REPLY}"
  SHF.hasFilterOpts && SHF.addFilter 'a' 'lowpass'
}

SHM.doMjpeg() {
  SHM.doQuality 'video' 2 31
  SHM.doWiseman
  (( ${#REPLY} )) && {
    SHF.addWriterOpts 'v' 'huffman' 'optimal'
    EWS.echoRead '-huffman optimal'
  }
}

SHM.doMono() {
  SHU.readInt 'channel number' 0 255
  (( ${#REPLY} )) && {
    SHF.addFilter 'a' 'pan="mono|c0=c'"${REPLY}"'"'
    SHF.setOutputOpts 'a' 'ac' 1
    EWS.echoRead '-ac 1'
  }
}

SHM.doNlmeans() {
  SHF.addFilter 'v' 'nlmeans'
}

SHM.doNoautorotate() {
  SHF.setOutputOpts 'v' 'noautorotate'
}

SHM.doNtsc-dvd() {
  SHF.addWriterOpts 'v' 'target' 'ntsc-dvd' "${SHM_WISEMAN_V[@]}"
}

SHM.doNtsc-svcd() {
  SHM.doVcd 'ntsc-s'
}

SHM.doNtsc-vcd() {
  SHM.doVcd 'ntsc-'
}

SHM.doPass() {
  SHU.readInt 'pass number' 1 2
  (( ${#REPLY} )) && SHF.setOutputOpts 'm' 'pass' "${REPLY}"
}

SHM.doQuality() {
  local shmAbr="${1:0:1}"
  SHU.readInt "${1}"' quality' "${2}" "${3}"
  (( ${#REPLY} )) && SHF.addWriterOpts "${shmAbr}" 'q:'"${shmAbr}" "${REPLY}"
}

SHM.doScale() {
  SHU.readInt 'width' 1 65535
  (( ${#REPLY} )) && SHF.addFilterOpts 'w' "${REPLY}"
  SHU.readInt 'height' 1 65535
  (( ${#REPLY} )) && SHF.addFilterOpts 'h' "${REPLY}"
  SHF.hasFilterOpts && {
    SHU.readOpt SHM_SCALE_INTERPOLATION 'interpolation'
    (( ${#REPLY} )) && {
      local shmVal="${SHM_SCALE_INTERPOLATION[${REPLY}]}"
      case "${shmVal}" in
        'mitchell' )
          SHF.addFilterOpts 'flags' 'bicubic' 'param0' '1/3' 'param1' '1/3' ;;
        * )
          SHF.addFilterOpts 'flags' "${shmVal}" ;;
      esac
    }
    SHU.readOpt SHM_SCALE_KEEPASPECT 'method to keep the original aspect ratio'
    (( ${#REPLY} )) && SHF.addFilterOpts \
        'force_original_aspect_ratio' "${SHM_SCALE_KEEPASPECT[${REPLY}]}"
    SHF.addFilter 'v' 'scale'
  }
}

SHM.doSs() {
  SHU.readTime 'start time'
  (( ${#REPLY} )) && {
    [ "${REPLY:0:1}" == '-' ] && {
      SHF.setOutputOpts 'm' 'sseof' "${REPLY}" || :
    } || SHF.setOutputOpts 'm' 'ss' "${REPLY}"
  }
}

SHM.doT() {
  SHU.readTime 'duration'
  (( ${#REPLY} )) && SHF.setOutputOpts 'm' 't' "${REPLY}"
}

SHM.doTo() {
  SHU.readTime 'stop time'
  (( ${#REPLY} )) && SHF.setOutputOpts 'm' 'to' "${REPLY}"
}

SHM.doVcd() {
  SHF.addWriterOpts 'v' 'target' "${1}"'vcd' "${SHM_WISEMAN_V[@]}"
  SHF.addWriterOpts 'a' 'c:a' 'libtwolame' 'psymodel' 4
}

SHM.doVolume() {
  SHU.readInt 'gain in dB' -100 100
  (( ${#REPLY} )) && {
    SHF.addFilterOpts 'volume' "${REPLY}"'dB'
    SHF.addFilter 'a' 'volume'
  }
}

SHM.doWav() {
  SHF.addWriterOpts 'v' 'vn'
  (( ${#shfOop} )) && {
    shfOop="${shfOop%.wav}"'.wav'
    shfPag=6 || :
  } || {
    (( ${#shfOip} )) && {
      shfOop="${shfOip%.wav}"'.wav'
      shfPag=6 || :
    }
  } || {
    echo 'No file.'
    shfPag=1
  }
}

SHM.doWeb() {
  SHF.addWriterOpts 'v' 'c:v' 'libx264' 'crf' 23 'preset' 'slow'
  SHF.addWriterOpts 'a' 'c:a' 'aac' 'b:a' '128k'
  SHF.setOutputOpts 'a' 'ac' 2
}

SHM.doWeb-hd() {
  SHM.doWeb
  SHF.addFilter 'v' 'scale=w=1280:h=1280:flags=bicubic:param0=1/3:param1=1/3:force_original_aspect_ratio=decrease'
}

SHM.doWeb-sd() {
  SHM.doWeb
  SHF.addFilter 'v' 'scale=w=480:h=480:flags=bicubic:param0=1/3:param1=1/3:force_original_aspect_ratio=increase'
}

SHM.doWiseman() {
  echo 'Use slowest options?'
  SHU.readBoolOrBlank
  (( ${#REPLY} )) && {
    SHF.addWriterOpts 'v' "${SHM_WISEMAN_V[@]}"
    EWS.echoRead \
        '-cmp rd -dct faan -mbcmp rd -mbd rd -precmp rd -subcmp rd -trellis 2'
  }
}

SHM.doYadif() {
  SHU.readOpt SHM_YADIF_MODE 'mode'
  (( ${#REPLY} )) && SHF.addFilterOpts 'mode' "${SHM_YADIF_MODE[${REPLY}]}"
  SHU.readOpt SHM_YADIF_PARITY 'parity'
  (( ${#REPLY} )) && SHF.addFilterOpts 'parity' "${SHM_YADIF_PARITY[${REPLY}]}"
  SHU.readOpt SHM_YADIF_DEINT 'deint'
  (( ${#REPLY} )) && SHF.addFilterOpts 'deint' "${SHM_YADIF_DEINT[${REPLY}]}"
  SHF.addFilter 'v' 'yadif'
}

# sheff-main.sh~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
            shfRan= ;;
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
        (( shfPag == 2 )) && shfPag=5 || :
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
  shfPal="${shfPag}"
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
      (( shfPag == shfPal )) && {
        (( shfPag && shfPag++ )) || SHF.doMenu
      } ;;
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
