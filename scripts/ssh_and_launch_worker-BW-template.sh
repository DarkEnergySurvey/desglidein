#!/bin/bash

WORKER=$1

# Get the nodes names and put the in random tmp file
cat $PBS_NODEFILE  | sort -u > /tmp/ccm_nodelist_$$

# Here we loop over all the node available and ssh to them
IFS=$'\n' read -d '' -r -a lines < /tmp/ccm_nodelist_$$

for i in "${lines[@]}"
do
   echo ssh $i
   #ssh $i '{SHELL_SCRIPT} &
   sleep 10
done
echo "Done ssh to nodes"

tail -f $PBS_NODEFILE
