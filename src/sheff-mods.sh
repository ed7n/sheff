readonly -a SHF_FILTERS_A=(
  'aresample' 'volume' 'mono'
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
  'web-hd' 'web-sd' 'ntsc-dvd' 'ntsc-vcd' 'ntsc-svcd'
)
readonly -a SHF_WRITERS_A=(
  'aac' 'flac' 'libmp3lame' 'libopus' 'libtwolame' 'libvorbis'
)
readonly -a SHF_WRITERS_V=(
  'ffv1' 'mjpeg' 'libtheora' 'libvpx' 'libvpx-vp9' 'libx264' 'libx265' 'libxvid'
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
    SHF.addFilterOpts 'resampler' 'soxr'
    EWS.echoRead 'resampler=soxr'
    SHU.readInt 'SoXR precision in bits' 15 33
    (( ${#REPLY} )) && SHF.addFilterOpts 'precision' "${REPLY}"
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
  SHU.readInt 'constant rate factor' 0 63
  (( ${#REPLY} )) && SHF.addWriterOpts 'v' 'crf' "${REPLY}"
  SHU.readOpt SHM_X264_PRESET 'preset'
  (( ${#REPLY} )) \
      && SHF.addWriterOpts 'v' 'preset' "${SHM_X264_PRESET[${REPLY}]}"
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
