#!/usr/bin/env bash

# 'Forked' from, and hat-tip to: https://betterdev.blog/minimal-safe-bash-script-template/
# Also original was a gist here: https://gist.github.com/m-radzikowski/53e0b39e9a59a1518990e76c2bff8038

# Set options
set -o errexit -o nounset -o errtrace -o pipefail

# Trap signals/exits
cleanup() {
  EXIT_CODE=$?  # This must be the first line of the cleanup
  # Script cleanup here. Make sure cleanup is idempotent, as it could be called multiple times.
  # If you want more fine-grained cleanup, separate the traps and the functions.
  start
}
trap cleanup SIGINT SIGTERM ERR EXIT
clear_traps() {
  trap - SIGINT SIGTERM ERR EXIT
}

# Determine the directory this script is running in.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# Determine the absolute directory we are running in in case it's needed later.
# TODO: Untested.
if [[ ${OSTYPE} == linux-gnu* ]]; then
  ABS_SCRIPT_DIR=$(readlink -f "${SCRIPT_DIR}")
elif [[ ${OSTYPE} == darwin* ]]; then
  ABS_SCRIPT_DIR=$(greadlink -f "${SCRIPT_DIR}")
elif [[ ${OSTYPE} == cygwin ]]; then
  ABS_SCRIPT_DIR=$(readlink -f "${SCRIPT_DIR}")
elif [[ ${OSTYPE} == msys ]]; then
  ABS_SCRIPT_DIR=$(readlink -f "${SCRIPT_DIR}")
elif [[ ${OSTYPE} == win32 ]]; then
  ABS_SCRIPT_DIR=$(readlink -f "${SCRIPT_DIR}")
elif [[ ${OSTYPE} == freebsd* ]]; then
  ABS_SCRIPT_DIR=$(readlink -f "${SCRIPT_DIR}")
else
  ABS_SCRIPT_DIR=$(readlink -f "${SCRIPT_DIR}")
fi

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] [--no-color] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
--no-color      Switch off colorization
-f, --flag      Some flag description
-p, --param     Some param description
EOF
  exit
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m' INVERSE='\033[7m' RESET_INVERSE='\033[27m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # Default values of variables set from params
  FLAG=0
  PARAM=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -o xtrace ;;
    --no-color) NO_COLOR=1 ;;
    -f | --flag) FLAG=1 ;; # example flag
    -p | --param) # example named parameter
      PARAM="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  ARGS=("$@")

  # Check required params and arguments
  #[ -z "${PARAM-}" ] && usage && die "Missing required parameter: param"
  #[ ${#ARGS[@]} -eq 0 ] && usage && die "Missing script arguments"

  return 0
}

parse_params "$@"
setup_colors

# Script logic here, or `source this_script.sh` in your script if you want to treat it as a library.

LINE=_____________________________________________________________________

readonly DEFAULT_PICKED_GRAPH_DESC='All observations vs findings'
reset_state() {
	PICKED_GRAPH_DESC="${DEFAULT_PICKED_GRAPH_DESC}"
	PICKED_PLAN=any
	AR_TAG=latest
	CS_TAG=latest
	GRAPH_MINUTES=360
}

show_state() {
	#set -o | grep xtrace
	#set -o | grep verbose
	echo "CS_TAG='$CS_TAG'    AR_TAG='$AR_TAG'    PICKED_PLAN='$PICKED_PLAN'    PICKED_GRAPH_DESC='$PICKED_GRAPH_DESC'"
}

wait_for_return() {
	# Clear input buffer
	while read -t 0.01 -n 1; do : ; done
	echo ${LINE}
	echo "Done, return to continue"
	read -r
}

clear_screen() {
	# Clear screen, but add lines first to ensure no output is lost
	for i in {1..$(tput lines)}; do echo ""; done
	clear
}


run() {
	clear_screen
	set +e
	echo -e "${INVERSE}COMPLIANCE FRAMEWORK DEMO MENU - `date`${RESET_INVERSE}
${LINE}${RED}
${INVERSE}Options${RESET_INVERSE}
ga)           Graph observations vs findings   gao) Get all observations (summary)
gaf)          Get all findings                 k9s) Run k9s
plans)        Get plans                        pp)  Pick a plan to focus on
pt)           Pick docker container tags       li)  Load up images
r)            Restart demo                     br)  Build and restart local
v)            Toggle verbose flag              sh)  Give me a shell
make COMMAND) Run \`make COMMAND\`               cs)  Show current state
q)            Quit
${NOFORMAT}${LINE}${GREEN}
${INVERSE}Make Commands (m COMMAND)${RESET_INVERSE}`make help`
${NOFORMAT}${LINE}"

	echo -ne "${INVERSE}Input choice ==>${RESET_INVERSE} "
	unset ans
	read -r ans

	clear_screen
	if [[ $ans == ga ]]
	then
		date
		echo ${LINE}
		mkdir -p ~/cf_demo_logs
		curl -s http://localhost:8080/api/plan/"${PICKED_PLAN}"/results/any/compliance-over-time | jq -r '.[] | "\(.totalObservations),\(.totalFindings)"' | tail -"${GRAPH_MINUTES}" | asciigraph -d ',' -sn 2 -sc green,red -sl "Observations/min,Findings/min" -w 80 -h 12 -ub 12 -p 0 -lb 0 -c "${PICKED_GRAPH_DESC}"
		wait_for_return
	elif [[ $ans == gao ]]
	then
		curl -s http://localhost:8080/api/plan/"${PICKED_PLAN}"/results/any/observations | jq '[.[] | {collected, description, props: [.props[] | {name, value}]}]' | "$PAGER"
	elif [[ $ans == gaf ]]
	then
	 	curl -s http://localhost:8080/api/plan/"${PICKED_PLAN}"/results/any/findings | jq -r '.[]' | "$PAGER"
	elif [[ $ans == pp ]]
	then
		curl -s http://localhost:8080/api/plans | jq '.'
		echo -ne "${INVERSE}Input plan id ==>${RESET_INVERSE} "
		read -r PICKED_PLAN
		echo -ne "${INVERSE}Input description for graph ==>${RESET_INVERSE} "
		read -r PICKED_GRAPH_DESC
		if [[ $PICKED_PLAN == '' ]]
		then
			PICKED_PLAN=any
		fi
		if [[ $PICKED_GRAPH_DESC == '' ]]
		then
			PICKED_PLAN="${DEFAULT_PICKED_GRAPH_DESC}"
		fi
	elif [[ $ans == pt ]]
	then
		show_state
		echo ${LINE}
		echo -e "${INVERSE}Input new docker AR_TAG (assessment runtime) value."
		echo -ne "(hit return to keep current value ($AR_TAG); 'latest_local' may be what you want) ==>${RESET_INVERSE} "
		read -r new_ar_tag
		if [[ $new_ar_tag != '' ]]
		then
			docker pull ghcr.io/compliance-framework/assessment-runtime:$new_ar_tag || true
			kind load docker-image ghcr.io/compliance-framework/assessment-runtime:$new_ar_tag -n compliance-framework || true
			AR_TAG=$new_ar_tag
		fi
		echo ${LINE}
		echo -e "${INVERSE}Input new docker CS_TAG (configuration server) value."
		echo -ne "(hit return to keep current value ($CS_TAG); 'latest_local' may be what you want) ==>${RESET_INVERSE} "
		read -r new_cs_tag
		if [[ $new_cs_tag != '' ]]
		then
			docker pull ghcr.io/compliance-framework/configuration-service:$new_cs_tag || true
			kind load docker-image ghcr.io/compliance-framework/configuration-service:$new_cs_tag -n compliance-framework || true
			CS_TAG=$new_cs_tag
		fi
		wait_for_return
	elif [[ $ans == li ]]
	then
		load_images
		wait_for_return
	elif [[ $ans == k9s ]]
	then
		k9s
	elif [[ $ans == plans ]]
	then
		curl -s http://localhost:8080/api/plans | jq '.'
		wait_for_return
	elif [[ $ans == r ]]
	then
		AR_TAG=${AR_TAG} CS_TAG=${CS_TAG} make k8s_restart || true
		wait_for_return
	elif [[ $ans == br ]]
	then
		export AR_TAG=latest_local
		export CS_TAG=latest_local
		(cd ../configuration-service && make build-local)
		(cd ../assessment-runtime && make build-local)
		load_images
		pwd
		make k8s_restart || true
		wait_for_return
	elif [[ $ans == q ]]
	then
		clear_traps
		exit 0
	elif [[ $ans == cs ]]
	then
		show_state
		wait_for_return
	elif [[ $ans == v ]]
	then
		set -x
		set -v
	elif [[ $(echo $ans | cut -d' ' -f1) == make || $(echo $ans | cut -d' ' -f1) == m ]]
	then
		make $(echo $ans | cut -d' ' -f2)
		wait_for_return
	elif [[ $ans == "" ]]
	then
		true
	elif [[ $ans == "sh" ]]
	then
		zsh
	else
		echo $ans | cut -f1
		echo "Unrecognised: $ans - did you mean 'make $ans'?"
		wait_for_return
	fi
}


load_images() {
	docker pull ghcr.io/compliance-framework/assessment-runtime:${AR_TAG} || true
	kind load docker-image ghcr.io/compliance-framework/assessment-runtime:${AR_TAG} -n compliance-framework || true
	docker pull ghcr.io/compliance-framework/configuration-service:${CS_TAG} || true
	kind load docker-image ghcr.io/compliance-framework/configuration-service:${CS_TAG} -n compliance-framework || true
}

start() {
	while true
	do
		run
	done
}

reset_state
start
