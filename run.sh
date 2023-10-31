#!/bin/bash
#
#
set -e -o pipefail

PID=$$
TEMP=/tmp/$PID

print_help() {
    echo -e "$0\n\t -t|--testdir <test directory>\tTest directory to run
    \t -l|--local\t\t\tWeather to run test in local cluster
    \t -a|--address <cluster address>\tLocal cluster auth address
    \t -u|--username <username>\tAuth username"
}

runtest() {
    testdir=$1
    username=$2
    echo -e "==== Running [ `echo $testdir |tr a-z A-Z` ] test ====\n"
    cd $testdir
    sh test.sh -sc |while read line; do
        logger -t "run/$testdir" -s $username "$line"
    done
}

options=$(getopt -o lht:a:u: --long local,test:,address:,username:,help -- "$@")
eval set -- "$options"

if [[ $# < 2 ]]; then
    print_help
    exit 1
fi

while true; do
    case "$1" in
        -t|--testdir)
            shift
            TESTDIR=$1
            ;;
        -a|--address)
            shift
            ADDRESS=$1
            ;;
        -l|--local)
            shift 
            LOCAL=true
            ;;
        -u|--username)
            shift
            USERNAME=$1
            ;;
        -h|--help)
            shift
            print_help
            exit 0
            ;;
        "--")
            shift
            break
            ;;
        *)
            shift
            ;;
    esac
done

if [ $TESTDIR ]; then
    if [ ! -d "$TESTDIR" ]; then
        echo "ERR: \`${TESTDIR}\` test directory does not exist"
        exit 1
    fi
else
    echo "ERR: -t|--test is a required parameter"
    exit 1
fi

if [ -n "$LOCAL" ]; then
    if [ -z "$ADDRESS" ]; then
        echo "ERR: -a|--address is required when --local is set"
        exit 1
    fi

    echo -e "Running tests locally as \`$USERNAME\`"

    # set Kubeconfig for dev and managed namespace:
    [ -z "$USERNAME" ] && read -p "Username: " USERNAME
    read -p "Password: " -s PASSWORD

    DEV_KUBECONFIG=${TEMP}-dev-kubeconfig
    MANAGED_KUBECONFIG=${TEMP}-managed-kubeconfig
    
    export DEV_KUBECONFIG MANAGED_KUBECONFIG
    touch $DEV_KUBECONFIG $MANAGED_KUBECONFIG

    oc login $ADDRESS -u $USERNAME -p "${PASSWORD}"  --insecure-skip-tls-verify=true --kubeconfig $DEV_KUBECONFIG
    oc project dev-release-team-tenant --kubeconfig $DEV_KUBECONFIG
    
    oc login $ADDRESS -u $USERNAME -p "${PASSWORD}"  --insecure-skip-tls-verify=true --kubeconfig $MANAGED_KUBECONFIG
    oc project managed-release-team-tenant --kubeconfig $MANAGED_KUBECONFIG
fi

runtest $TESTDIR $USERNAME
