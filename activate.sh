#!/bin/bash
# -c echo source
AUTOENV_AUTH_FILE=~/.autoenv_authorized
: "${AUTOENV_ENTER_FILENAME:=.env-enter}"
: "${AUTOENV_LEAVE_FILENAME:=.env-leave}"

if [[ -n "${ZSH_VERSION}" ]]
then __array_offset=1
else __array_offset=0
fi

autoenv_files()
{
  typeset _src _dst _home
  typeset -a _files
  _home="$(dirname "$HOME")"
  _env="$1"
  _src="$2"
  _dst="$3"

  _files=( $(
    builtin cd "$_src"
    while [[ "$PWD" != "/" && "$PWD" != "$_home" && ! "$_dst" =~ $PWD ]]
    do
      _file="$PWD/$_env"
      if [[ -e "${_file}" ]]
      then echo "${_file}"
      fi
      builtin cd .. &>/dev/null
    done
  ) )

  # shellcheck disable=2068
  echo ${_files[@]}
}


autoenv_walk()
{
  typeset _src _dst _file _leave _n _i
  _src="$1"
  _dst="$2"
  _leave=( $(autoenv_files "$AUTOENV_LEAVE_FILENAME" "$_src" "$_dst" ) )
  _enter=( $(autoenv_files "$AUTOENV_ENTER_FILENAME" "$_dst" "$_src" ) )

  _n=$(( ${#_leave[@]} + __array_offset - 1 ))
  _i=$_n
  while (( _i >= __array_offset ))
  do
    envfile=${_leave[_i]}
    if [ -n "$envfile" ]; then
      autoenv_check_authz_and_run "$envfile"
    fi
    : $(( _i -= 1 ))
  done

  _n=$(( ${#_enter[@]} + __array_offset - 1))
  _i=$__array_offset
  while (( _i <= _n ))
  do
    envfile=${_enter[_i]}
    if [ -n "$envfile" ]; then
      autoenv_check_authz_and_run "$envfile"
    fi
    : $(( _i += 1 ))
  done
}

autoenv_env() {
  builtin echo "autoenv:" "$@"
}

autoenv_printf() {
  builtin printf "autoenv: "
  builtin printf "$@"
}

autoenv_indent() {
  cat -e "$@" | sed 's/.*/autoenv:     &/'
}

autoenv_hashline()
{
  typeset envfile hash
  envfile=$1
  if which shasum &> /dev/null
  then hash=$(shasum "$envfile" | cut -d' ' -f 1)
  else hash=$(sha1sum "$envfile" | cut -d' ' -f 1)
  fi
  echo "$envfile:$hash"
}

autoenv_check_authz()
{
  typeset envfile hash
  envfile=$1
  hash=$(autoenv_hashline "$envfile")
  touch $AUTOENV_AUTH_FILE
  # shellcheck disable=1001
  \grep -Gq "$hash" $AUTOENV_AUTH_FILE
}

autoenv_check_authz_and_run()
{
  typeset envfile
  envfile=$1
  if autoenv_check_authz "$envfile"; then
    autoenv_source "$envfile"
    return 0
  fi
  if [[ -z $MC_SID ]]; then #make sure mc is not running
    autoenv_env
    autoenv_env "WARNING:"
    autoenv_env "This is the first time you are about to source $envfile":
    autoenv_env
    autoenv_env "    --- (begin contents) ---------------------------------------"
    autoenv_indent "$envfile"
    autoenv_env
    autoenv_env "    --- (end contents) -----------------------------------------"
    autoenv_env
    autoenv_printf "Are you sure you want to allow this? (y/N) "
    read answer
    if [ "x$answer" = "xy" ] || [ "x$answer" = "xY" ]; then
      autoenv_authorize_env "$envfile"
      autoenv_source "$envfile"
    fi
  fi
}

autoenv_deauthorize_env() {
  typeset envfile
  envfile=$1
  # shellcheck disable=1001
  \grep -Gv "$envfile:" "$AUTOENV_AUTH_FILE" > $AUTOENV_AUTH_FILE.$$.tmp
  # shellcheck disable=1001
  \mv "$AUTOENV_AUTH_FILE.$$.tmp" "$AUTOENV_AUTH_FILE"
}

autoenv_authorize_env() {
  typeset envfile
  envfile=$1
  autoenv_deauthorize_env "$envfile"
  autoenv_hashline "$envfile" >> $AUTOENV_AUTH_FILE
}

autoenv_source() {
  typeset allexport
  allexport=$(set +o | grep allexport)
  set -a
  source "$1"
  eval "$allexport"
}

if declare -f cd >/dev/null ; then
    # shellcheck disable=2034
    eval "autoenv_prev_$(declare -f cd)"
fi

cd()
{
  typeset _leaving="$PWD"

  # shellcheck disable=2034
  if declare -f autoenv_prev_cd >/dev/null ; then
    autoenv_prev_cd "$@"
  else
    builtin cd "$@"
  fi

  if (( $? == 0 ))
  then
    autoenv_walk "$_leaving" "$PWD"
    return 0
  fi
  return $?
}

autoenv_walk "/" "$PWD"
