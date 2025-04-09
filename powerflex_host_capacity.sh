#!/bin/bash 
# This is a simple bash script that uses curl to make API calls, and jq to parse the json from those calls.
# Make sure you have curl and jq installed

#SCRIPT VARIABLES - PUT YOUR POWERFLEX MANAGER CREDENTIALS IN HERE
PFXM_IP=<YOUR_IP>
PFXM_USER=<YOUR_USERNAME>
PFXM_PASSWORD=<YOUR_PASSWORD>

###########################################################################################################################################################  
#SCRIPT COLORS FOR ECHO  
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
LIGHT_PURPLE='\033[1;35m'
YELLOW='\033[1;33m'  
NC='\033[0m'

#Start SCRIPT
echo " "
echo -e "${YELLOW}######################################################################################################## ${NC}"
echo -e "${YELLOW}# PowerFlex 4.6+ Host Capacity Script ${NC}"
echo -e "${YELLOW}# Version: 1.0.0"
echo -e "${YELLOW}# Requirements: curl and jq packages ${NC}"
echo -e "${YELLOW}# Support: No support provided, use and edit to your needs ${NC}"
echo -e "${YELLOW}# PowerFlex API Reference: https://developer.dell.com/apis/4008/versions/4.6.1/PowerFlex_REST_API.json ${NC}"
echo -e "${YELLOW}######################################################################################################## ${NC}"
echo " "

#Log into API and get a token
TOKEN=$(curl -s -k --location --request POST "https://${PFXM_IP}/rest/auth/login" --header "Accept: application/json" --header "Content-Type: application/json" --data "{\"username\": \"${PFXM_USER}\",\"password\": \"${PFXM_PASSWORD}\"}") 
ACCESS_TOKEN=$(echo "${TOKEN}" | jq -r .access_token) 

#Get system id
SYSTEM=$(curl -k -s -X GET "https://$PFXM_IP/api/types/System/instances/" -H 'Accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN")
SYSTEM_ID=$(echo $SYSTEM | jq .[].id| tr -d '"')
echo -e "${GREEN}[SUCCESS] - Connected to PowerFlex system ${SYSTEM_ID}. querying hosts:${NC}"
echo " "
echo -e "${CYAN}[QUERYING HOSTS]${NC}"

#Create CSV to hold information for hosts
CSV_NAME="${SYSTEM_ID}_capacity_report.csv"
echo "HOST_NAME,SDC_ID,OPERATING_SYSTEM,SDC_STATE,SDC_VERSION,VOLUMES_MAPPED,VOLUME_PROVISIONED_KIB,VOLUME_USED_KIB" > $CSV_NAME

#Get all SDCs and then extract all SDC IDs into an array
HOSTS=$(curl -k -s -X GET "https://$PFXM_IP/api/types/Sdc/instances" -H 'Accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN")
HOST_IDS=$(echo $HOSTS | jq .[].id)
readarray -t bash_array < <(echo "$HOST_IDS")


#For each SDC look up its name, volumes, and total up volume allocated
for HOST in "${bash_array[@]}"; do
  SDC_ID=$(echo $HOST | tr -d '"')
  
  #Get all mapped volumes for the SDC ID
  VOLUMES=$(curl -k -s -X GET "https://$PFXM_IP/api/instances/Sdc::$SDC_ID/relationships/Volume" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json")
  VOLUME_IDS=$(echo $VOLUMES | jq -r '.[].id')
  
  #Get the SDC's name
  SDC_INFO=$(curl -k -s -X GET "https://$PFXM_IP/api/instances/Sdc::$SDC_ID" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json")
  SDC_NAME=$(echo $SDC_INFO | jq .name | tr -d '"')
  SDC_OS=$(echo $SDC_INFO | jq .osType | tr -d '"')
  SDC_STATE=$(echo $SDC_INFO | jq .mdmConnectionState | tr -d '"')
  SDC_VERSION=$(echo $SDC_INFO | jq .installedSoftwareVersionInfo | tr -d '"')

  #Progress
  echo -e "${CYAN}-HOST [${SDC_NAME}] FOUND${NC}"   
  
  #Total up Used for this SDC 
  TOTAL_IN_USE_KIB=0
  TOTAL_VOLUMES=0
  TOTAL_SIZE_KIB=0
  #for each volume id
  for volume in $VOLUME_IDS; do
    #get all volume info
    VOLUME_INFO=$(curl -k -s -X GET "https://$PFXM_IP/api/instances/Volume::$volume" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json")
    
    #extract the volume size
    VOLUME_SIZE=$(echo $VOLUME_INFO | jq .sizeInKb)
    
    #extract vtree id and use it to find how much is written to the volume
    VTREE_ID=$(echo $VOLUME_INFO | jq -r '.vtreeId')
    VTREE_STATS=$(curl -k -s -X GET "https://$PFXM_IP/api/instances/VTree::$VTREE_ID/relationships/Statistics" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json")
    VTREE_IN_USE=$(echo $VTREE_STATS | jq -r '.netCapacityInUseInKb')
    
    #update the host totals
    TOTAL_IN_USE_KIB=$(($TOTAL_IN_USE_KIB + $VTREE_IN_USE))
    TOTAL_VOLUMES=$(($TOTAL_VOLUMES + 1))
    TOTAL_SIZE_KIB=$(($TOTAL_SIZE_KIB + $VOLUME_SIZE))
  done
  #Add entry to CSV
  echo "${SDC_NAME},${SDC_ID},${SDC_OS},${SDC_STATE},${SDC_VERSION},${TOTAL_VOLUMES},${TOTAL_SIZE_KIB},${TOTAL_IN_USE_KIB}" >> $CSV_NAME

  #Print out total capacity
  sleep 1
  echo -e "${CYAN}-HOST [$SDC_NAME] COMPLETE ${NC}"  
  
  #sleep to slow the API calls
  sleep 2
done

echo -e "${CYAN}[QUERYING HOSTS COMPLETE]${NC}"
echo " "
echo -e "${GREEN}######################################################################################################## ${NC}"
echo -e "${GREEN}# Script has completed. ${NC}"
echo -e "${GREEN}# CSV output can be found at $PWD$/$CSV_NAME ${NC}"
echo -e "${GREEN}#${NC}${YELLOW} NOTE: SCRIPT IS NOT CLUSTER AWARE - EACH CLUSTER MEMBER WILL BE A TOTAL OF ALL THE CLUSTER VOLUMES ${NC}"
echo -e "${GREEN}######################################################################################################## ${NC}"
echo " "