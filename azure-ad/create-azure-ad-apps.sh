#!/bin/bash
set -e

# load environment variables
. ./setenv.sh

# create the Azure Active Directory server application
az ad app create --display-name ${RBAC_SERVER_APP_NAME} \
    --password "${RBAC_SERVER_APP_SECRET}" \
    --identifier-uris "${RBAC_SERVER_APP_URL}" \
    --reply-urls "${RBAC_SERVER_APP_URL}" \
    --required-resource-accesses @manifest-server.json

RBAC_SERVER_APP_ID=$(az ad app list --display-name $RBAC_SERVER_APP_NAME --query [].appId -o tsv)
RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID=$(az ad app show --id ${RBAC_SERVER_APP_ID} --query oauth2Permissions[0].id -o tsv)

# create service principal for the server application
az ad sp create --id ${RBAC_SERVER_APP_ID}

# update the application
az ad app update --id ${RBAC_SERVER_APP_ID} --set groupMembershipClaims=All

# grant permissions to server application
RBAC_SERVER_APP_RESOURCES_API_IDS=$(az ad app permission list --id $RBAC_SERVER_APP_ID --query [].resourceAppId --out tsv | xargs echo)
for RESOURCE_API_ID in $RBAC_SERVER_APP_RESOURCES_API_IDS;
do
  az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_SERVER_APP_ID
done

# generate manifest for client application
cat > ./manifest-client.json << EOF
[
    {
      "resourceAppId": "${RBAC_SERVER_APP_ID}",
      "resourceAccess": [
        {
          "id": "${RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID}",
          "type": "Scope"
        }
      ]
    }
]
EOF

# create client application
az ad app create --display-name ${RBAC_CLIENT_APP_NAME} \
    --native-app \
    --reply-urls "${RBAC_SERVER_CLIENT_URL}" \
    --required-resource-accesses @manifest-client.json

RBAC_CLIENT_APP_ID=$(az ad app list --display-name ${RBAC_CLIENT_APP_NAME} --query [].appId -o tsv)

# create service principal for the client application
az ad sp create --id ${RBAC_CLIENT_APP_ID}

# remove manifest-client.json
rm ./manifest-client.json

# grant permissions to server application
RBAC_CLIENT_APP_RESOURCES_API_IDS=$(az ad app permission list --id $RBAC_CLIENT_APP_ID --query [].resourceAppId --out tsv | xargs echo)
for RESOURCE_API_ID in $RBAC_CLIENT_APP_RESOURCES_API_IDS;
do
  az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_CLIENT_APP_ID
done

# Output terraform variables
echo "
export TF_VAR_rbac_server_app_id="${RBAC_SERVER_APP_ID}"
export TF_VAR_rbac_server_app_secret="${RBAC_SERVER_APP_SECRET}"
export TF_VAR_rbac_client_app_id="${RBAC_CLIENT_APP_ID}"
export TF_VAR_tenant_id="${RBAC_AZURE_TENANT_ID}"
"

