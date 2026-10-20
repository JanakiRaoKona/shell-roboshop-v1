#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="janakiraodevops.online"
hosted_zone_id="Z03779601M3DCD1PTYF54"

for instance in $@ 
do
    echo "Creating instance: ${instance}"
done