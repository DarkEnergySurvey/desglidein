#!/bin/bash 

# Make sure we run bash
. /opt/modules/default/init/bash

local_host_name=`hostname -f`
echo LOCAL 
echo $local_host_name 

# Make sure that we can ping to the ORACLE DB
ping -c 4 leovip148.ncsa.uiuc.edu
#ping -c 4 leovip148.ncsa.illinois.edu
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

export _condor_LOCAL_DIR={SCRATCH_PATH}/condor_local/desdm/${local_host_name}
export _condor_NUM_CPUS={NCPU}
export _condor_UID_DOMAIN=ncsa.illinois.edu
export _condor_FILESYSTEM_DOMAIN=ncsa.illinois.edu
export _condor_MAIL=/bin/mail
export _condor_STARTD_NOCLAIM_SHUTDOWN={NO_CLAIM_SHUTDOWN}

# Extra conf for IP address
export _condor_COLLECTOR_HOST={IP_SUBMIT_SITE} 
export _condor_CCB_ADDRESS={IP_SUBMIT_SITE} 

# Only allow the user
#export _condor_START_owner={USER}

# glidein name -- not ready yet
#export _condor_GLIDEIN_NAME={GLIDEIN_NAME}
#export _condor_STARTD_EXPRS=GLIDEIN_NAME
##export _condor_IS_GLIDEIN=True
##export _condor_STARTD_EXPRS="IS_GLIDEIN, START, DaemonStopTime, GLIDEIN_NAME"

# Option A -- wild do not use
# no_glidein_name
#_condor_START = TRUE

# Option B -- default
# yes USER only
#export _condor_START = (Owner =="{USER}")
#_condor_START = (XXXXX == {USER_COSMO})

# Option C
# yes gliden-name and USER_COSMO 
#_condor_START = (XXXXX == {USER_COSMO}) && (YYYY == {GLIDEIN_NAME})

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
  mkdir -p {SCRATCH_PATH}/condor_local
  mkdir -p {SCRATCH_PATH}/condor_local/desdm
  mkdir -p {SCRATCH_PATH}/condor_local/desdm/${local_host_name}
  mkdir -p {SCRATCH_PATH}/condor_local/desdm/${local_host_name}/log
  mkdir -p {SCRATCH_PATH}/condor_local/desdm/${local_host_name}/execute
  echo "Script_Launching condor master";
  echo ${_condor_SBIN}/condor_master
  ${_condor_SBIN}/condor_master -dyn -f -r {TIME_TO_LIVE}

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

