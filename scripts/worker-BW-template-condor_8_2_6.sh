#!/bin/bash 

# Make sure we run bash
. /opt/modules/default/init/bash

local_host_name=`hostname -f`

echo LOCAL 
echo $local_host_name 

#####################################################################################################
# Here we use the already setup EUPS variables and replace them as strings
#    CONDORSTRIPPED_DIR
#    DESGLIDEIN_DIR
#####################################################################################################
export CONDOR_CONFIG={DESGLIDEIN_DIR}/config/worker-general-condor_8_2_6.config
export _condor_RELEASE_DIR={CONDORSTRIPPED_DIR}
export _condor_SHARED_PORT={CONDORSTRIPPED_DIR}/libexec/condor_shared_port
export _condor_SBIN={CONDORSTRIPPED_DIR}/sbin

export _condor_LOCAL_DIR=${HOME}/condor_local/desdm/${local_host_name}
export _condor_NUM_CPUS={NCPU}
export _condor_UID_DOMAIN=ncsa.illinois.edu
export _condor_FILESYSTEM_DOMAIN=ncsa.illinois.edu
export _condor_MAIL=/bin/mail
export _condor_STARTD_NOCLAIM_SHUTDOWN={NO_CLAIM_SHUTDOWN}

# Extra conf for IP address
export _condor_COLLECTOR_HOST={IP_SUBMIT_SITE} 
export _condor_CCB_ADDRESS={IP_SUBMIT_SITE} 

# Hack to add extra missing libs
export LD_LIBRARY_PATH=/u/sciteam/daues/condor/pcre/install/lib:$LD_LIBRARY_PATH

psef=`ps -ef | grep condor`
echo psef
echo $psef
if [[ "$psef" == *condor_master* ]]
then
  echo "condor_master is already running on this node.";
  sleep 3600
else
  mkdir -p ${HOME}/condor_local
  mkdir -p ${HOME}/condor_local/desdm
  mkdir -p ${HOME}/condor_local/desdm/${local_host_name}
  mkdir -p ${HOME}/condor_local/desdm/${local_host_name}/log
  mkdir -p ${HOME}/condor_local/desdm/${local_host_name}/execute
  echo "Script_Launching condor master";
  echo ${_condor_SBIN}/condor_master
  ${_condor_SBIN}/condor_master -f

  #################################
  # Alternative method with PID
  #pidfile=/tmp/${local_host_name}-condor.pid
  #echo "Will write PID to:${pidfile}"
  #${_condor_SBIN}/condor_master -pidfile ${pidfile}
  #echo "waiting 10s for condor_master to start"
  #sleep 10
  #PID=`cat ${pidfile}`
  #echo "PID:${PID}"
  #################################

fi

echo "Finishing worker"

#####################################
# Alternative method with PID
#while [[ ( -d /proc/${PID} ) ]]; do
#    sleep 1
#    echo "waiting for ${PID}"
#done
#####################################

