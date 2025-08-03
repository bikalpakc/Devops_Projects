#!//bin/bash

############################
# Author : Bikalpa KC
# Date : 12/19/2024
#
# Version: v1
#
# This script will report the usage of AWS Resources.
############################

set -x

# AWS S3
# AWS EC2
# AWS Lambda
# AWS IAM Users

# List S3 buckets:
echo"List of s3 buckets:"
aws s3 ls > ResourceTracker_output

# List EC2 Instance:
echo"List of EC2 instances:"
aws ec2 describe-instances >> ResourceTracker_output

echo"Only EC2 instance id:"
aws ec2 describe-instances | jq'.Reservations[].Instances[].InstanceId' >> ResourceTracker_output

# List Lambda:
echo"List of Lambda:"
aws lambda list-functions >> ResourceTracker_output

# List IAM users
echo"List of IAM users:"
aws iam list-users >> ResourceTracker_output

