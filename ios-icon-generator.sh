#!/bin/bash

set -e

spushd() {
  pushd "$1" > /dev/null 2>&1
}

spopd() {
  popd > /dev/null 2>&1
}

info() {
  local green="\033[1;32m"
  local normal="\033[0m"
  echo -e "[${green}INFO${normal}] $1"
}

cmdcheck() {
  command -v $1>/dev/null 2>&1 || { error >&2 "Please install command $1 first."; exit 1; }
}

error() {
  local red="\033[1;31m"
  local normal="\033[0m"
  echo -e "[${red}ERROR${normal}] $1"
}

warn() {
  local yellow="\033[1;33m"
  local normal="\033[0m"
  echo -e "[${yellow}WARNING${normal}] $1"
}

yesno() {
  while true;do
    read -rp "$1 (y/n)" yn
    case $yn in
      [Yy]) $2;break;;
      [Nn]) exit;;
      *) echo 'Please enter y or n.'
    esac
  done
}

curdir() {
  if [ ${0:0:1} = '/' ] || [ ${0:0:1} = '~' ]; then
    dirname "$0"
  elif [ -L "$0" ];then
    name=$(readlink "$0")
    dirname "${name}"
  else
    echo "$(pwd)/$(dirname "$0")"
  fi
}

myos() {
  echo $(uname|tr "[:upper:]" "[:lower:]")
}

#########################################
###           GROBLE DEFINE           ###
#########################################

VERSION=2.0.0
AUTHOR=smallmuou

#########################################
###             ARG PARSER            ###
#########################################

usage() {
prog=$(basename "$0")
cat << EOF
$prog version $VERSION by $AUTHOR

USAGE: $prog [OPTIONS] srcfile dstpath

DESCRIPTION:
    This script aim to generate iOS/macOS/watchOS APP icons more easier and simply.

    srcfile - The source png image. Preferably above 1024x1024
    dstpath - The destination path where the icons generate to.

OPTIONS:
    -h      Show this help message and exit

EXAMPLES:
    $prog 1024.png ~/123

EOF
exit 1
}

while getopts 'h' arg; do
  case $arg in
    h)
      usage
      ;;
    ?)
      # OPTARG
      usage
      ;;
  esac
done

shift $(($OPTIND - 1))

[ $# -ne 2 ] && usage

#########################################
###            MAIN ENTRY             ###
#########################################

cmdcheck sips
src_file=$1
dst_path=$2

# Check source file
[ ! -f "$src_file" ] && { error "The source file $src_file does not exist, please check it."; exit 1; }

# Check width and height
src_width=$(sips -g pixelWidth "$src_file" 2>/dev/null|awk '/pixelWidth:/{print $NF}')
src_height=$(sips -g pixelHeight "$src_file 2>/dev"/null|awk '/pixelHeight:/{print $NF}')

[ -z "$src_width" ] &&  { error "The source file $src_file is not a image file, please check it."; exit 1; }

if [ "${src_width}" -ne "${src_height}" ];then
  warn "The height and width of the source image are different, will cause image deformation."
fi

# create dst directory
[ ! -d "$dst_path" ] && mkdir -p "$dst_path"

# iOS sizes refer to https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/app-icon/
# macOS sizes refer to https://developer.apple.com/design/human-interface-guidelines/macos/icons-and-images/app-icon/
# watchOS sizes refer to https://developer.apple.com/design/human-interface-guidelines/watchos/icons-and-images/home-screen-icons/
#
# name  size
sizes_mapper=\
"icon_16       16
icon_16@2x    32
icon_32       32
icon_32@2x    64
icon_128      128
icon_128@2x   256
icon_256      256
icon_256@2x   512
icon_512      512
icon_512@2x   1024
icon_20       20
icon_20@2x    40
icon_20@3x    60
icon_29       29
icon_29@2x    58
icon_29@3x    87
icon_40       40
icon_40@2x    80
icon_40@3x    120
icon_60@2x    120
icon_60@3x    180
icon_76       76
icon_76@2x    152
icon_83.5@2x  167
icon_1024     1024
icon_24@2x    48
icon_27.5@2x  55
icon_86@2x    172
icon_98@2x    196
icon_108@2x   216
icon_44@2x    88
icon_50@2x    100"

OLD_IFS=$IFS
IFS=$'\n'
srgb_profile='/System/Library/ColorSync/Profiles/sRGB Profile.icc'

for line in $sizes_mapper
do
  name=$(echo $line|awk '{print $1}')
  size=$(echo $line|awk '{print $2}')
  info "Generating: $name.png"
  out="${dst_path}/${name}.png"
  if [ -f "${srgb_profile}" ];then
    sips --matchTo "${srgb_profile}" -z "${size}" "${size}" "${src_file}" --out "${out}" > /dev/null 2>&1
  else
    sips -z "${size}" "${size}" "${src_file}" --out "${out}" > /dev/null
  fi
done

info "Congratulations! All icons for iOS/macOS/watchOS APP are generate to the directory: $dst_path"

IFS=$OLD_IFS
