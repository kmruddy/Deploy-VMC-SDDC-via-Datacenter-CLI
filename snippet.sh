#!/bin/sh
# Author: Alan Renouf
# Product: VMware Cloud on AWS
# Description: VMware Cloud on AWS Single Host Deployment Script using DCLI 
# Requirements:
#  - DCLI (http://vmware.com/go/dcli) or pip install dcli
#  - JQ (https://stedolan.github.io/jq/)

# Set jq location 
JQ="/Users/renoufa/Downloads/jq"

# Set details for SDDC
SDDC_NAME="1-Node-SDDC-VIA-DCLI"
NUM_HOSTS=1
REGION="US_WEST_2"

# Check if JQ exists
if [ ! -e $JQ ]
then
    echo "JQ not found at $JQ, please check path"
else
    # --- Deployment code  ---
    # Get ORG ID
    ORG_JSON=$(dcli +vmc +skip com vmware vmc orgs list +formatter json)
    ORGID=$(echo $ORG_JSON | $JQ -r '.[0].id')
    ORGNAME=$(echo $ORG_JSON | $JQ -r '.[0].display_name')
    Echo "Org:" $ORGNAME "ID:" $ORGID

    # Get Linked Account ID
    ACCOUNTID=$(dcli +vmc +skip com vmware vmc orgs accountlink connectedaccounts get --org $ORGID +formatter json | $JQ -r '.[0].id ')
    Echo "Account ID: " $ACCOUNTID

    # Get Subnet ID
    VMC_CASE_REGION=$(Echo "$REGION" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
    SUBNETS_JSON=$(dcli +vmc +skip com vmware vmc orgs accountlink compatiblesubnets get --org $ORGID --linked-account-id $ACCOUNTID --region $VMC_CASE_REGION +formatter json)
    SUBNETKEY=$(echo $SUBNETS_JSON | $JQ -r '.vpc_map | keys [0]')
    SUBNETID=$(echo $SUBNETS_JSON | $JQ -r '.vpc_map."'$SUBNETKEY'".subnets[0].subnet_id')
    SUBNET_CIDR_BLOCK=$(echo $SUBNETS_JSON | $JQ -r '.vpc_map."'$SUBNETKEY'".subnets[0].subnet_cidr_block')
    Echo "Subnet CIDR" $SUBNET_CIDR_BLOCK "ID:" $SUBNETID
    
    # Deploy the SDDC
    dcli +vmc +skip com vmware vmc orgs sddcs create --org $ORGID --name $SDDC_NAME --num-hosts $NUM_HOSTS --provider AWS --region $REGION --account-link-sddc-config '[
        {
            "connected_account_id": "'$ACCOUNTID'",
            "customer_subnet_ids": [
                "'$SUBNETID'"
            ]
        }
    ]'
fi
