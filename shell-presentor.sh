#!/bin/bash

set -e

PN="${BASH_SOURCE[0]##*/}"
PD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SAY_OPT=""

if ! type say ; then
	exit 1
fi

function usage() {
	cat <<EOF
Usage: ${PN} [Options] <Txt file>
Options:
  -h : show this help message
EOF
	[ $# -gt 0 ] && { echo ; echo "$@" ; exit 1 ; }
	exit 0
}

for i in $@ ; do
	case "${i}" in
	-h) usage ;;
	*) txtfile="${i}" ;;
	esac
done

if [ -z "${txtfile}" ] ; then
	usage
fi

CLEAR(){ echo -en "\033c";}
CIVIS(){ echo -en "\033[?25l";}
CNORM(){ echo -en "\033[?12l\033[?25h";}
TPUT(){ echo -en "\033[${1};${2}H";}
DRAW(){ echo -en "\033%@";echo -en "\033(0";}
WRITE(){ echo -en "\033(B";}
BLUE(){ echo -en "\033c\033[0;1m\033[37;44m\033[J";}
NORM(){ echo -en "\033c\033[0;1m\033[33;42m\033[J";}

K_ESC="$(echo -e "\e")"
C_N=$'\e[0m'
C_CUR_TEXT=$'\e[37;44;01m'

max="$(wc -l "${txtfile}" | cut -d' ' -f1)"
line=1

if (( max < 1 )) ; then
	usage "Empty txt file"
fi

function draw() {
	local i
	local imax

	CLEAR
	printf "q: Exit | r: Repeat\n"
	printf "================================="
	echo

	i=$(( (line - 5) >= 1 ? (line - 5) : 1 ))
	for ((; i<line ; i++)) ; do
		printf "${C_PRE_TEXT}%s${C_N}\n" "$(sed -n "${i}p" "${txtfile}")"
	done

	printf "${C_CUR_TEXT}%s${C_N}\n" "$(sed -n "${line}p" "${txtfile}")"

	imax=$(( (line + 5) <= max ? (line + 5) : max ))
	for (( i=line+1 ; i<=imax ; i++)) ; do
		printf "${C_POST_TEXT}%s${C_N}\n" "$(sed -n "${i}p" "${txtfile}")"
	done
}

speekid=""
function speek() {
	if [ "${speekid}" ] && [ -d "/proc/${speekid}" ] ; then
		kill -9 "${speekid}"
	fi
	{ sed -n "${line}p" "${txtfile}" | say ${SAY_OPT} ; } &
	speekid="$!"
}

exec 3>&2
exec 2>/dev/null
draw
while true ; do
	read -s -n 1 ans
	if [ "${ans}" == "${K_ESC}" ] ; then
		read -s -n 2 ans
		case "${ans}" in
		"[A") line="$(( (line - 1) >= 1 ? (line - 1) : 1 ))" ;;
		"[B") line="$(( (line + 1) <= max ? (line + 1) : max ))" ;;
		esac
		draw
		speek
	elif [ "${ans}" == "r" ] ; then
		speek
	elif [ "${ans}" == "q" ] ; then
		break
	fi
done
exec 2>&3
exec 3>&-

