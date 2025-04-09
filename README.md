# Overview
This is a basic shell script to total up the capacity provisioned and used by each host connected to the PowerFlex system.

The script will create a .csv file with the capacity information by host.

**Note:** This script is not cluster aware and will total up capacity for each cluster node like its a standalone host.

### Download the script:
- ```wget https://raw.githubusercontent.com/murphyry/powerflex-host-capacity/refs/heads/main/powerflex_host_capacity.sh```
### Edit the script and add your PowerFlex Manager username, password, and IP address:
- ```vim powerflex_host_capacity.sh```
### Make the script executable:
- ```chmod +x powerflex_host_capacity.sh```
### Run the script executable:
- ```bash powerflex_host_capacity.sh```

