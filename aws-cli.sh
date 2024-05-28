#!/bin/bash

vpcId=$(aws ec2 create-vpc --cidr-block 10.10.0.0/16 --region us-east-1 | jq -r '.Vpc.VpcId')

igwId=$(aws ec2 create-internet-gateway --region us-east-1 | jq -r '.InternetGateway.InternetGatewayId')
aws ec2 attach-internet-gateway --internet-gateway-id $igwId --vpc-id $vpcId --region us-east-1

routetableID=$(aws ec2 create-route-table --vpc-id $vpcId --region us-east-1 | jq -r '.RouteTable.RouteTableId')
aws ec2 create-route --route-table-id $routetableID --destination-cidr-block 0.0.0.0/0 --gateway-id $igwId --region us-east-1

publicsubnetID1=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.10.0.0/24 --region us-east-1 --availability-zone us-east-1a | jq -r '.Subnet.SubnetId')
publicsubnetID2=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.10.1.0/24 --region us-east-1 --availability-zone us-east-1b | jq -r '.Subnet.SubnetId')


privatesubnetID1=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.10.2.0/24 --region us-east-1 --availability-zone us-east-1a | jq -r '.Subnet.SubnetId')
privatesubnetID2=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.10.3.0/24 --region us-east-1 --availability-zone us-east-1b | jq -r '.Subnet.SubnetId')


aws ec2 modify-subnet-attribute --subnet-id $publicsubnetID1 --map-public-ip-on-launch --region us-east-1
aws ec2 modify-subnet-attribute --subnet-id $publicsubnetID2 --map-public-ip-on-launch --region us-east-1


aws ec2 associate-route-table --route-table-id $routetableID --subnet-id $publicsubnetID1 --region us-east-1
aws ec2 associate-route-table --route-table-id $routetableID --subnet-id $publicsubnetID2 --region us-east-1


ec2SGid=$(aws ec2 create-security-group --group-name CustomPublicSG1 --description "My security group" --vpc-id $vpcId --region us-east-1 | jq -r '.GroupId')

aws ec2 authorize-security-group-ingress \
    --group-id $ec2SGid \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region us-east-1

aws ec2 authorize-security-group-ingress \
    --group-id $ec2SGid \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region us-east-1

aws ec2 run-instances --image-id ami-0bb84b8ffd87024d8 --instance-type t2.micro --subnet-id $publicsubnetID1 --security-group-ids $ec2SGid --region us-east-1