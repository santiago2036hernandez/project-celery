#!/bin/bash

sudo yum update -y
sudo yum install -y ecs-init
sudo service docker start
sudo start ecs

echo ECS_CLUSTER=base-project-ecs-cluster-stg >> /etc/ecs/ecs.config
cat /etc/ecs/ecs.config | grep "ECS_CLUSTER"
