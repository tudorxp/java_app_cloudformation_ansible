#!/bin/bash

REGION="us-west-2"

# deleting stack 
aws cloudformation delete-stack \
	--region $REGION \
	--stack-name tudorxp-blockwizard 

if [ $? != 0 ]; then echo "Error occurred while deleting stack"; exit 1; fi

aws cloudformation wait stack-delete-complete --stack-name tudorxp-blockwizard --region $REGION

if [ $? != 0 ]; then echo "Error occurred while deleting stack"; exit 1; fi

echo "Delete complete"
