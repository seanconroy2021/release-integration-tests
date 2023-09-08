#!/bin/sh

if [ -z "$OFFLINE_TOKEN" ]; then
    echo "$( date -Ins --utc ) ERROR Please export your OFFLINE_TOKEN variable" 1>&2
    exit 1
fi

curl \
    --silent \
    --header "Accept: application/json" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "client_id=cloud-services" \
    --data-urlencode "refresh_token=${OFFLINE_TOKEN}" \
    "https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token" \
    | jq --raw-output ".access_token"
