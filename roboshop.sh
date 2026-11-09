#!/bin/bash

SG_ID="sg-03acb919ece3742ee"
AMI_ID="ami-0055977a6e828a4f4"

for instance in $@
do

    INSTANCE_ID=$( aws ec2 run-instances 
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text
        )
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
        )
    fi

    eho "IP Adress of $instance is $IP"

done