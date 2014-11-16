#!/bin/bash

PN="${BASH_SOURCE[0]##*/}"
PD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SAY_OPT="${SAY_OPT}"
speek_speed="${SPEED:-180}"

if ! type awk killall say ; then
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

K_ESC="$(echo -e "\e")"
C_N=$'\e[0m'
C_CUR_TEXT=$'\e[37;44;01m'

max="$(wc -l "${txtfile}" | awk '{print $1}')"
line=1

if (( max < 1 )) ; then
	usage "Empty txt file"
fi

function is_empty_line() {
	local txt
	txt="$(sed -n "${line}p" "${txtfile}")"
	if [ "${txt}" ] ; then
		return 1
	else
		return 0
	fi
}

function draw() {
	local i
	local imax

	CLEAR
	printf "line: ${line} | q: Exit | r: Repeat | w: Up | s: Down | +/-: Speed ${speek_speed}\n"
	printf "=================================\n"

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

function speek() {
	killall say
	{ sed -n "${line}p" "${txtfile}" | say -r ${speek_speed} ${SAY_OPT} ; } &
}

exec 3>&2
exec 2>/dev/null
draw
speek
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
	elif [ "${ans}" == "w" ] ; then
		line="$(( (line - 1) >= 1 ? (line - 1) : 1 ))"
		is_empty_line && line="$(( (line - 1) >= 1 ? (line - 1) : 1 ))"
		draw
		speek
	elif [ "${ans}" == "s" ] ; then
		line="$(( (line + 1) <= max ? (line + 1) : max ))"
		is_empty_line && line="$(( (line + 1) <= max ? (line + 1) : max ))"
		draw
		speek
	elif [ "${ans}" == "r" ] ; then
		speek
	elif [ "${ans}" == "+" ] ; then
		speek_speed=$(( speek_speed + 10 ))
		draw
	elif [ "${ans}" == "-" ] ; then
		speek_speed=$(( speek_speed - 10 ))
		draw
	elif [ "${ans}" == "q" ] ; then
		killall say
		break
	fi
done
exec 2>&3
exec 3>&-

