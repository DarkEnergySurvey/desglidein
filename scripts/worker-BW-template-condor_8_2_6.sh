#!/bin/bash 

# Make sure we run bash
. /opt/modules/default/init/bash

local_host_name=`hostname -f`
echo LOCAL 
echo $local_host_name 

# Make sure that we can ping to the ORACLE DB
ping -c 4 desdb.ncsa.illinois.edu

if [ "$?" -ne "0" ]; then
  mkdir -p ${HOME}/failed_dbconnections
  date=`date "+%Y-%m-%d_%H:%M:%S"`
  echo "Ping failed for $local_host_name." 
  echo "Ping failed for $local_host_name." > ${HOME}/failed_dbconnections/${local_host_name}_${date}.txt
  exit
else
  echo "Ping succeeded"
fi

# EUPS options
# Now we copy and untar the EUPS stack if desired. 
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

export _condor_USE_SHARED_PORT=False
export _condor_LOCAL_DIR={SCRATCH_PATH}/cloc/${local_host_name}
export _condor_NUM_CPUS={NCPU}
export _condor_UID_DOMAIN=ncsa.illinois.edu
export _condor_FILESYSTEM_DOMAIN=ncsa.illinois.edu
export _condor_MAIL=/bin/mail
export _condor_STARTD_NOCLAIM_SHUTDOWN={NO_CLAIM_SHUTDOWN}

# Extra conf for IP address
export _condor_COLLECTOR_HOST={IP_SUBMIT_SITE} 
export _condor_CCB_ADDRESS={IP_SUBMIT_SITE} 

# setup _condor_GLIDEIN_NAME
{condor_GLIDEIN_NAME}

# setup _condor_START
{condor_START}

# Hack to add extra missing libs
export LD_LIBRARY_PATH=/mnt/b/projects/sciteam/bbcb/des/extralibs/install/lib:$LD_LIBRARY_PATH

psef=`ps -ef | grep condor`
echo psef
echo $psef
if [[ "$psef" == *condor_master* ]]
then
  echo "condor_master is already running on this node.";
  sleep 3600
else
  mkdir -p {SCRATCH_PATH}/cloc
  mkdir -p {SCRATCH_PATH}/cloc/${local_host_name}
  mkdir -p {SCRATCH_PATH}/cloc/${local_host_name}/log
  mkdir -p {SCRATCH_PATH}/cloc/${local_host_name}/spool
  mkdir -p {SCRATCH_PATH}/cloc/${local_host_name}/execute
  echo "Script_Launching condor master";
  echo ${_condor_SBIN}/condor_master
  ${_condor_SBIN}/condor_master -f -r {TIME_TO_LIVE}

fi

echo "Finishing worker"

