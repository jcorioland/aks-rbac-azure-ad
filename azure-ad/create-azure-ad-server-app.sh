#!/bin/bash
set -e

# load environment variables
export RBAC_AZURE_TENANT_ID="801dc5e8-3f2d-4070-ab27-a7497e430784"
export RBAC_SERVER_APP_NAME="AKSAADServer2"
export RBAC_SERVER_APP_URL="http://aksaadserver2"
export RBAC_SERVER_APP_SECRET="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

# create the Azure Active Directory server application
echo "Creating server application..."
az ad app create --display-name ${RBAC_SERVER_APP_NAME} \
    --password "${RBAC_SERVER_APP_SECRET}" \
    --identifier-uris "${RBAC_SERVER_APP_URL}" \
    --reply-urls "${RBAC_SERVER_APP_URL}" \
    --homepage "${RBAC_SERVER_APP_URL}" \
    --required-resource-accesses @manifest-server.json

RBAC_SERVER_APP_ID=$(az ad app list --display-name $RBAC_SERVER_APP_NAME --query [].appId -o tsv)
RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID=$(az ad app show --id ${RBAC_SERVER_APP_ID} --query oauth2Permissions[0].id -o tsv)

# update the application
az ad app update --id ${RBAC_SERVER_APP_ID} --set groupMembershipClaims=All

# create service principal for the server application
echo "Creating service principal for server application..."
az ad sp create --id ${RBAC_SERVER_APP_ID}

# grant permissions to server application
echo "Granting permissions to the server application..."
RBAC_SERVER_APP_RESOURCES_API_IDS=$(az ad app permission list --id $RBAC_SERVER_APP_ID --query [].resourceAppId --out tsv | xargs echo)
for RESOURCE_API_ID in $RBAC_SERVER_APP_RESOURCES_API_IDS;
do
  if [ "$RESOURCE_API_ID" == "00000002-0000-0000-c000-000000000000" ]
  then
    az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_SERVER_APP_ID --scope "User.Read"
  elif [ "$RESOURCE_API_ID" == "00000003-0000-0000-c000-000000000000" ]
  then
    az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_SERVER_APP_ID --scope "Directory.Read.All"
  else
    az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_SERVER_APP_ID --scope "user_impersonation"
  fi
done

echo "The Azure Active Directory application has been created. You need to ask an Azure AD Administrator to go the Azure portal an click the `Grant permissions` button for this app."
echo "Copy the following environment variables to the client application creation script:"

echo "
export RBAC_SERVER_APP_ID="${RBAC_SERVER_APP_ID}"
export RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID="${RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID}"
export RBAC_SERVER_APP_SECRET="${RBAC_SERVER_APP_SECRET}"
"