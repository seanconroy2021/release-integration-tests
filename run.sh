#!/bin/bash
#
#
set -e -o pipefail

PID=$$
TEMP=/tmp/$PID

function print_help() {
    echo -e "$0\n\t -t|--test <test name>\t\tTest name to run
    \t -l|--local\t\t\tWeather to run test locally
    \t -a|--address <cluster address>\tCluster auth address
    \t -u|--username <username>\tAuth username"
}

options=$(getopt -o lht:a:u: --long local,test:,address:,username:,help -- "$@")
eval set -- "$options"

if [[ $# < 2 ]]; then
    print_help
    exit 1
fi

while true; do
    case "$1" in
        -t|--test)
            shift
            TEST_DIR=$1
            ;;
        -a|--address)
            shift
            AUTH_HOST=$1
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

if [ $TEST_DIR ]; then
    if [ ! -d "$TEST_DIR" ]; then
        echo "ERR: \`${TEST_DIR}\` test directory does not exist"
        exit 1
    fi
else
    echo "ERR: -t|--test is a required parameter"
    exit 1
fi

if [ -n "$LOCAL" ]; then
    if [ -z $AUTH_HOST ]; then
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

    oc login $AUTH_HOST -u $USERNAME -p "${PASSWORD}"  --insecure-skip-tls-verify=true --kubeconfig $DEV_KUBECONFIG
    oc project dev-release-team-tenant --kubeconfig $DEV_KUBECONFIG
    
    oc login $AUTH_HOST -u $USERNAME -p "${PASSWORD}"  --insecure-skip-tls-verify=true --kubeconfig $MANAGED_KUBECONFIG
    oc project managed-release-team-tenant --kubeconfig $MANAGED_KUBECONFIG
fi

echo -e "==== Running [ `echo $TEST_DIR |tr a-z A-Z` ] test ====\n"
cd $TEST_DIR
sh test.sh
