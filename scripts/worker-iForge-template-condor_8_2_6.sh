#!/bin/bash 

local_host_name=`hostname -f`

echo LOCAL 
echo $local_host_name 

# EUPS options
# Now we copy and untar the EUPS stack if desired. For now this is only suported for Blue Waters
{INSTALL_EUPS}

# Make a local .eups_$USER on /tmp
mkdir -p /tmp/.eups_{USER}

#####################################################################################################
# Here we use the already setup EUPS variables and replace them as strings
#    CONDORSTRIPPED_DIR
#    DESGLIDEIN_DIR
#####################################################################################################
export CONDOR_CONFIG={DESGLIDEIN_DIR}/config/worker-general-condor_8_2_6.config
export _condor_RELEASE_DIR={CONDORSTRIPPED_DIR}
export _condor_SHARED_PORT={CONDORSTRIPPED_DIR}/libexec/condor_shared_port
export _condor_SBIN={CONDORSTRIPPED_DIR}/sbin

export _condor_LOCAL_DIR=/scratch/users/{USER}/condor_local/desdm/${local_host_name}
export _condor_NUM_CPUS={NCPU}
export _condor_UID_DOMAIN=iforge.ncsa.illinois.edu
export _condor_FILESYSTEM_DOMAIN=iforge.ncsa.illinois.edu
export _condor_MAIL=/bin/mail
export _condor_STARTD_NOCLAIM_SHUTDOWN={NO_CLAIM_SHUTDOWN}

# Extra conf for IP address
export _condor_COLLECTOR_HOST={IP_SUBMIT_SITE} 
export _condor_CCB_ADDRESS={IP_SUBMIT_SITE} 

# glidein name
export _condor_GLIDEIN_NAME={GLIDEIN_NAME}
export _condor_STARTD_EXPRS=GLIDEIN_NAME
#export _condor_IS_GLIDEIN=True
#export _condor_STARTD_EXPRS="IS_GLIDEIN, START, DaemonStopTime, GLIDEIN_NAME"

psef=`ps -ef | grep condor`
echo psef
echo $psef

if [[ "$psef" == *condor_master* ]]
then
  echo "condor_master is already running on this node.";
  sleep 3600
else
  #
  mkdir -p /scratch/users/{USER}/condor_local
  mkdir -p /scratch/users/{USER}/condor_local/desdm
  mkdir -p /scratch/users/{USER}/condor_local/desdm/${local_host_name}
  mkdir -p /scratch/users/{USER}/condor_local/desdm/${local_host_name}/log
  mkdir -p /scratch/users/{USER}/condor_local/desdm/${local_host_name}/execute
  #
  echo "Script_Launching condor master";
  echo ${_condor_SBIN}/condor_master
  ${_condor_SBIN}/condor_master -dyn -f -r {TIME_TO_LIVE}

fi

echo "Finishing worker"

