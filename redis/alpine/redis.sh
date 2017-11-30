#!/bin/bash
# Copyright 2017 Ismail KABOUBI
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
echo "Launching redis orchestrator"
# Define config file locations
SENTINEL_CONF=/etc/redis/sentinel.conf
MASTER_CONF=/etc/redis/master.conf
SLAVE_CONF=/etc/redis/slave.conf

# Launch master when `MASTER` environment variable is set
function launchmaster() {
  if [[ ! -e /redis-master-data ]]; then
    echo "Redis master data doesn't exist, data won't be persistent!"
    mkdir /redis-master-data
  fi
  redis-server $MASTER_CONF --protected-mode no
}

# Launch sentinel when `SENTINEL` environment variable is set
function launchsentinel() {
  while true; do
    master=$(redis-cli -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
      master="${master//\"}"
    else
      master=$(hostname -i)
    fi

    redis-cli -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done

  echo "sentinel monitor mymaster ${master} 6379 2" > ${SENTINEL_CONF}
  echo "sentinel down-after-milliseconds mymaster 60000" >> ${SENTINEL_CONF}
  echo "sentinel failover-timeout mymaster 180000" >> ${SENTINEL_CONF}
  echo "sentinel parallel-syncs mymaster 1" >> ${SENTINEL_CONF}
  echo "sentinel client-reconfig-script mymaster /var/redis/reconfig.sh"
  echo "bind 0.0.0.0"

  redis-sentinel ${SENTINEL_CONF} --protected-mode no
}

# Launch slave when `SLAVE` environment variable is set
function launchslave() {
  if [[ ! -e /redis-master-data ]]; then
    echo "Redis master data doesn't exist, data won't be persistent!"
    mkdir /redis-master-data
  fi

  while true; do
    master=$(redis-cli -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
      master="${master//\"}"
    else
      echo "Failed to find master."
      sleep 60
      exit 1
    fi
    redis-cli -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done
  sed -i "s/%master-ip%/${master}/" $SLAVE_CONF
  sed -i "s/%master-port%/6379/" $SLAVE_CONF
  redis-server $SLAVE_CONF --protected-mode no
}


# Seed the cluster with a single master
if [[ "${HOSTNAME}" == *"-server-0" ]]; then
  export MASTER="true"
  echo "Seeding Redis cluster with initial master"
  launchmaster
  exit 0
fi
# Check if MASTER environment variable is set
#if [[ "${MASTER}" == "true" ]]; then
#  echo "Launching Redis in Master mode"
#  launchmaster
#  exit 0
#fi
# Check if SENTINEL environment variable is set
if [[ "${SENTINEL}" == "true" ]]; then
  echo "Launching Redis Sentinel"
  launchsentinel
  exit 0
fi
# Launch slave if nothing is set
echo "Launching Redis in Replica mode"
launchslave
