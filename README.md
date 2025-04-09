# Overview
This is a basic shell script to total up the capacity provisioned and used by each host connected to the PowerFlex system.

The script will create a .csv file with the capacity information by host.

**Note:** This script is not cluster aware and will total up capacity for each cluster node like its a standalone host.

![Screenshot of the script being run.](https://github.com/murphyry/powerflex-host-capacity/blob/main/script_output_example.PNG)

![Screenshot of the csv output.](https://github.com/murphyry/powerflex-host-capacity/blob/main/csv_example.png)

# Directions
### Pre-reqs:
- This script makes API calls to the PowerFlex Manager API using the curl package. Check if curl is installed by running ```curl -V```
- This script parses the API call output using the jq package. Check if jq is installed by running ```jq```
### Download the script:
- ```wget https://raw.githubusercontent.com/murphyry/powerflex-host-capacity/refs/heads/main/powerflex_host_capacity.sh```
### Edit the script and add your PowerFlex Manager username, password, and IP address in the "SCRIPT VARIABLES" section:
- ```vim powerflex_host_capacity.sh```
### Make the script executable:
- ```chmod +x powerflex_host_capacity.sh```
### Run the script executable:
- ```bash powerflex_host_capacity.sh```

