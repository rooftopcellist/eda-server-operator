#!/bin/bash

# Variables
OPM=$1
BUNDLE_IMGS=$2
CSV_VERSION=$3
VERSION=$4

# Render the current index image to yaml
$OPM render quay.io/ansible/eda-server-catalog:latest > eda-operator-catalog/existing-eda-catalog.json

# Filter the existing FBC to only use the EDA Server Operator
jq 'select(.name == "eda-server-operator" or .package == "eda-server-operator")' eda-operator-catalog/existing-eda-catalog.json > eda-operator-catalog/filtered-eda-catalog.json

# Remove existing FBC to only use filtered FBC
rm -rf ./eda-operator-catalog/existing-eda-catalog.json

echo "> Add new bundles to the index"
opm render "$BUNDLE_IMGS" >>  eda-operator-catalog/filtered-eda-catalog.json

echo "> Set replaces for the index"
RELEASED_EDA_VERSION=$(jq -rs '.[] | select(.schema == "olm.channel" and .name == "alpha") | .entries[].name' eda-operator-catalog/filtered-eda-catalog.json)

echo "> Add new channels to the index"

echo "$CSV_VERSION"
echo "$VERSION"
echo "$RELEASED_EDA_VERSION"

echo  '{
    "schema": "olm.channel",
    "name": "alpha",
    "package": "eda-server-operator",
    "entries": [
    {
        "name": "'"$CSV_VERSION"'",
        "skipRange": ">=0.0.1 <'"$VERSION"'.1",
        "replaces": "'"$RELEASED_EDA_VERSION"'"
    }
    ]
}'

# Delete 0.0.2 bundle
jq 'del(.entries[] | select(.name=="eda-server-operator.v0.0.2"))' eda-operator-catalog/filtered-eda-catalog.json > temp.json && mv temp.json eda-operator-catalog/filtered-eda-catalog.json

# echo "> Set replaces for the index"
# echo "> Replaces set for: $RELEASED_EDA_VERSION\n"
# echo "> Add new channels to the index"

# # Remove the existing alpha channel entry
# jq 'del(.entries[] | select(.name=="alpha"))' eda-operator-catalog/filtered-eda-catalog.json > temp.json && mv temp.json eda-operator-catalog/filtered-eda-catalog.json



# # # Add the new alpha channel entry
# # jq --arg CSV_VERSION "$CSV_VERSION" --arg VERSION "$VERSION" --arg RELEASED_EDA_VERSION "$RELEASED_EDA_VERSION" '.entries += [
# #     {
# #         "name": $CSV_VERSION,
# #         "skipRange": ">=0.0.1 <${VERSION}.1",
# #         "replaces": $RELEASED_EDA_VERSION
# #     }
# # ]' eda-operator-catalog/filtered-eda-catalog.json > temp.json && mv temp.json eda-operator-catalog/filtered-eda-catalog.json

# # Add a new alpha channel
# jq  '. += {
#         "schema": "olm.channel",
#         "name": "alpha",
#         "package": "eda-server-operator",
#         "entries": [
#             {
#                 "name": "'"$CSV_VERSION"'",
#                 "skipRange": ">=0.0.1 <'"$VERSION"'.1",
#                 "replaces": "'"$RELEASED_EDA_VERSION"'"
#             }
#     ]
# }' eda-operator-catalog/filtered-eda-catalog.json > temp.json && mv temp.json eda-operator-catalog/filtered-eda-catalog.json
