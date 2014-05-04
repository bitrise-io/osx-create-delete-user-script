#!/bin/bash

#
# based on: https://gist.github.com/taylor/1380946
#  fork: https://gist.github.com/viktorbenei/9920634
#

# NOTE: GID 20 is staff group -- see more with: dscl . list groups gid
DEFAULT_GID=20
DEFAULT_GROUP=staff
DEFAULT_SHELL=/bin/bash
DEFAULT_HOME_BASE=/Users

_DEBUG_ON=""

me=$(basename $0)

usage() {
  printf "
Usage  
  $me <username> <password>

Note: Probably have to run with sudo
"
  #$me <username> <password> [-home <path>] [-uid <id>] [-gid <id>] [-shell <path>]
}

_create_user() {
  new_user="$1"
  new_psw="$2"
  new_home="$3"
  new_shell="$4"
  new_uid="$5"
  new_gid="$6"
  new_name="$7"

  # special user-group - used for total isolation
  group_name="group-${new_name}"
  sudo dscl . -create "/Groups/${group_name}"
  sudo dscl . -append "/Groups/${group_name}" gid "${new_gid}"
  # sudo dscl . -append /Groups/dba passwd "*"

  OSX_USER="/Users/$new_user"
  dscl . -create "${OSX_USER}" && \
    dscl . -create "${OSX_USER}" NFSHomeDirectory "$new_home" && \
    dscl . -create "${OSX_USER}" UserShell "$new_shell" && \
    dscl . -create "${OSX_USER}" UniqueID "$new_uid" && \
    dscl . -create "${OSX_USER}" PrimaryGroupID "$new_gid" && \
    dscl . -passwd "${OSX_USER}" "$new_psw" && \
    ( [ ! -z "$new_name" ] &&  dscl . -create "${OSX_USER}" RealName "$new_name" )

  # special user-group - used for total isolation
  dseditgroup -o edit -a "$new_user" -t user "$group_name"

  return $?
}

log()  { printf "$*\n" ; return $? ;  }
fail() { log "\nERROR: $*\n" ; exit 1 ; }

# TODO: accept more options
if [ -z "$1" ] ; then
  usage
  exit 0
fi

if [ -z "$2" ] ; then
  usage
  exit 0
fi

new_user="$1"
new_psw="$2"
new_shell=$DEFAULT_SHELL
new_uid=$(($(dscl . -list /Users uid | sort -nk2 | tail -n 1 | awk '{print $2}')+1))
new_gid=$(($(dscl . -list /Groups gid | sort -nk2 | tail -n 1 | awk '{print $2}')+1))
new_name="$new_user"
home_base=$DEFAULT_HOME_BASE
new_home="${home_base}/$new_user"
# special user-group - used for total isolation
new_group="group-${new_name}"

log "Creating user: $new_user"

# make sure the user does not exists
usertest="$(/usr/bin/dscl . -search /Users name "$new_user" 2>/dev/null)"
if ! [[ -z "$usertest" ]]; then printf "\nUser already exists! : $new_user\n\n"; exit 1; fi

[ "$_DEBUG_ON" ] && set -x
_create_user "$new_user" "$new_psw" "$new_home" "$new_shell" "$new_uid" "$new_gid" "$new_name"
[ "$?" = 0 ] && mkdir -p "$new_home"

if [ "$?" = 0 -a "$new_home" != "/" ] ; then
  chown -R "${new_user}:${new_group}" "${new_home}"
fi

log "Creating user: $new_user [done]"

set +x