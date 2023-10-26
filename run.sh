#!/bin/bash
#
#
set -e -o pipefail

PID=$$
TEMP=/tmp/$PID

function print_help() {
    echo -e "$0\t -t|--test <test name>\tTest name to run"
    echo -e "\t -l|--local\tWeather to run test locally"
    echo -e "\t -a|--address <cluster address>\tCluster auth address"
    echo -e "\t -u|--username <username>\tAuth username"
}

options=$(getopt -o lt:a:u: --long local,test:,address:,username: -- "$@")
eval set -- "$options"


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
        "--")
            shift
            break
            ;;
        *)
            shift
           ;;
    esac
done

if [ ! -d "$TEST_DIR" ]; then
    echo "ERR: \`${TEST_DIR}\` test directory does not exist"
    exit 1
fi

echo -e "==== Running [ `echo $TEST_DIR |tr a-z A-Z` ] test ====\n"

if [ -n "$LOCAL" ]; then

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

cd $TEST_DIR
sh test.sh
