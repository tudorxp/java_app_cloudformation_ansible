#!/bin/bash

AH=`dirname $0`


# generate a key for future non-priviledged user access to the instances (e.g. for further deployment etc)
mkdir -p $AH/credentials

if [ ! -f $AH/credentials/user_app_key ]; then ssh-keygen -N "" -f $AH/credentials/user_app_key &>/dev/null; fi

# provision hosts
# ssh key checking disabled for this exercise
cd $AH
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory setup.yml 

if [ $? != 0 ]; then 
	echo "Error during provisioning - fix me please"
	exit 1
fi

# get URL
broker_ip=`cat inventory |grep blockwizard_node_name=broker|cut -f1 -d" "`
echo
echo "Blockwizard app started and should soon be available at:"
echo "http://$broker_ip:16000/blocks"
echo

elk_ip=`cat inventory |grep -1 elk\]|tail -1`
elk_password=`cat credentials/bitnami_user_password |sed "s/.*'user' and '\(.*\)'\..*/\1/"`
echo "Logs are being aggregated to ELK at: http://$elk_ip/elk"
echo "  login using user 'user' and password '$elk_password' "
echo

