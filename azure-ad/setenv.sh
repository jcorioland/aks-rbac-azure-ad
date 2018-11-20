#!/bin/bash

export RBAC_AZURE_TENANT_ID="801dc5e8-3f2d-4070-ab27-a7497e430784"
export RBAC_SERVER_APP_NAME="AKSAADServer2"
export RBAC_SERVER_APP_URL="http://aksaadserver2"
export RBAC_SERVER_APP_SECRET="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
export RBAC_CLIENT_APP_NAME="AKSAADClient2"
export RBAC_SERVER_CLIENT_URL="http://aksaadclient2"