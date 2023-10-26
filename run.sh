#!/bin/bash
#
#
set -o pipefail

PID=$$
TEMP=/tmp/$PID

function print_help() {
    echo -e "$0\t -t|--test <TEST TO RUN>"
}

options=$(getopt -o t:a:u: --long test:,address:,username: -- "$@")
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

cd $TEST_DIR
sh test.sh
