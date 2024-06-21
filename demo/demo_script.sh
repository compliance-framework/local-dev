#!/usr/bin/env bash

# 'Forked' from, and hat-tip to: https://betterdev.blog/minimal-safe-bash-script-template/
# Also original was a gist here: https://gist.github.com/m-radzikowski/53e0b39e9a59a1518990e76c2bff8038

# Set options
set -o errexit -o nounset -o errtrace -o pipefail

# Trap signals/exits
cleanup() {
  EXIT_CODE=$?  # This must be the first line of the cleanup
  trap - SIGINT SIGTERM ERR EXIT
  # Script cleanup here. Make sure cleanup is idempotent, as it could be called multiple time.
  # If you want more fine-grained cleanup, separate the traps and the functions.
}
trap cleanup SIGINT SIGTERM ERR EXIT

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
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
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

#msg "${RED}Reading parameters:${NOFORMAT}"
#msg "- flag: ${FLAG}"
#msg "- param: ${PARAM}"
#msg "- arguments: ${ARGS[*]-}"

cd $SCRIPT_DIR/..


while true
do
	set +e
	cat <<- EOF

		_____________________________________________________________________
		Input a task:

		ga) Graph all observations vs findings
		gao) Get all observations
		gps) Get all problematic subjects (findings)
		jm) Jump onto mongo
		lar) Assessment runtime logs
		lcs) Configuration service logs
		ln) NATS logs
		pids) Get plan ids
		v) toggle verbose

		q) quit

	EOF

	read ans

	if [[ $ans == ga ]]
	then
		while true; do echo ___________________________________________________________________________________; date; mkdir -p ~/cf_demo_logs; d=$(date +%s); curl -s http://localhost:8080/api/plan/any/results/any/compliance-over-time | jq -r '.[] | "\(.totalObservations),\(.totalFindings)"' > ~/cf_demo_logs/$d.output; tail -30 ~/cf_demo_logs/$d.output | asciigraph -d ',' -sn 2 -sc green,red -sl "Observations/min","Findings/min" -w 80 -h 12 -ub 12 -p 0 -lb 0 -c 'All observations vs findings' | tee ~/cf_demo_logs/$d.asciigraph; sleep 15; done
	elif [[ $ans == gao ]]
	then
		curl -s http://localhost:8080/api/plan/any/results/any/observations | jq '[.[] | {collected, description, props: [.props[] | {name, value}]}]'
	elif [[ $ans == gps ]]
	then
	 	curl -s http://localhost:8080/api/plan/any/results/any/findings | jq -r '.[] | .description'
	elif [[ $ans == jm ]]
	then
		docker exec -ti local-dev-mongodb-1 mongosh
	elif [[ $ans == lar ]]
	then
		docker logs local-dev-assessment-runtime-1 -f
	elif [[ $ans == lcs ]]
	then
		docker logs local-dev-configuration-service-1 -f
	elif [[ $ans == nl ]]
	then
		docker logs local-dev-nats-1 -f
	elif [[ $ans == pids ]]
	then
		curl -s http://localhost:8080/api/plans
	elif [[ $ans == q ]]
	then
		exit 0
	elif [[ $ans == v ]]
	then
		set -x
		set -v
	fi
done
