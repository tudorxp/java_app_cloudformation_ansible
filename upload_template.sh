#!/bin/bash

aws s3 cp cf_template_blockwizard.json s3://tudorxp-cf-templates --storage-class STANDARD_IA --acl public-read --region eu-west-2
