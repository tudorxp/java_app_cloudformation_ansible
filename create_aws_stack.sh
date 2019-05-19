#!/bin/bash

# Creating a series of EC2 machines and populating an ansible inventory
# We take 2 parameters, one is the AWS Key name to be used for access into the instances, and the other is the private key filename 

if [ $# != 2 ]; then
		echo "Usage: $0 <key_name_associated_with_AWS_EC2> <private_key_filename>"
		exit 1
fi

REGION="us-west-2"
KEYNAME=$1
KEYFILENAME=$2

# creating stack from template
aws cloudformation create-stack \
	--region $REGION \
	--stack-name tudorxp-blockwizard \
	--template-url https://tudorxp-cf-templates.s3.amazonaws.com/cf_template_blockwizard.json \
	--parameters ParameterKey=KeyName,ParameterValue=$KEYNAME 

if [ $? != 0 ]; then echo "Error occurred while creating stack"; exit 1; fi

# wait until stack is complete
aws cloudformation wait stack-create-complete --stack-name tudorxp-blockwizard --region $REGION

if [ $? != 0 ]; then echo "Error occurred while waiting for stack creation"; exit 1; fi

# Get external IPs of configured VMs
BROKERIP=`aws cloudformation describe-stacks --stack-name tudorxp-blockwizard --region $REGION --query "Stacks[0].Outputs[?OutputKey=='BrokerIP'].OutputValue" --output text`
NODE1IP=`aws cloudformation describe-stacks --stack-name tudorxp-blockwizard --region $REGION --query "Stacks[0].Outputs[?OutputKey=='Node1IP'].OutputValue" --output text`
NODE2IP=`aws cloudformation describe-stacks --stack-name tudorxp-blockwizard --region $REGION --query "Stacks[0].Outputs[?OutputKey=='Node2IP'].OutputValue" --output text`
ELKIP=`aws cloudformation describe-stacks --stack-name tudorxp-blockwizard --region $REGION --query "Stacks[0].Outputs[?OutputKey=='ELKIP'].OutputValue" --output text`

if [ $BROKERIP"x" == "x" -o $NODE1IP"x" == "x" -o $NODE2IP"x" == "x" ]; then echo "Error occurred while getting IPs"; exit 1; fi

# Generating static ansible inventory 
cat >inventory <<EOF

[blockwizard_brokers]
$BROKERIP blockwizard_app_port=16000 blockwizard_node_name=broker

[blockwizard_nodes]
$NODE1IP blockwizard_app_port=16001 blockwizard_node_name=node1
$NODE2IP blockwizard_app_port=16002 blockwizard_node_name=node2

[blockwizard_appservers:children]
blockwizard_brokers
blockwizard_nodes

[blockwizard_appservers:vars]
ansible_user=ubuntu
ansible_private_key_file=$2
ansible_python_interpreter=python3

[elk]
$ELKIP

[elk:vars]
ansible_user=bitnami
ansible_private_key_file=$2
ansible_python_interpreter=python3


EOF

# Running ansible -m ping to check connectivity
ANSIBLE_HOST_KEY_CHECKING=False ansible -i inventory all -m ping 
