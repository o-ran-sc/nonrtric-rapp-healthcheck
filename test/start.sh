#!/bin/bash

#  ============LICENSE_START===============================================
#  Copyright (C) 2022 Nordix Foundation. All rights reserved.
#  ========================================================================
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#  ============LICENSE_END=================================================
#

docker network create nonrtric-docker-net 2> /dev/null

DIR="$( cd "$( dirname "$0" )" && pwd )"

PMS_PORT=8081
docker run --detach --rm -v $DIR/application_configuration.json:/opt/app/policy-agent/data/application_configuration.json -p $PMS_PORT:$PMS_PORT -p 8433:8433 --network=nonrtric-docker-net --name=policy-agent-container nexus3.o-ran-sc.org:10002/o-ran-sc/nonrtric-plt-a1policymanagementservice:2.5.0
SIM_PORT=8085
docker run --detach --rm -p $SIM_PORT:$SIM_PORT -p 8185:8185 -e A1_VERSION=OSC_2.1.0 -e ALLOW_HTTP=true --network=nonrtric-docker-net --name=ric1 nexus3.o-ran-sc.org:10002/o-ran-sc/a1-simulator:2.3.1

docker run --detach --rm -p 8086:$SIM_PORT -p 8186:8185 -e A1_VERSION=STD_1.1.3 -e ALLOW_HTTP=true --network=nonrtric-docker-net --name=ric2 nexus3.o-ran-sc.org:10002/o-ran-sc/a1-simulator:2.3.1

retcode=1
while [ $retcode -ne 0 ]; do
    RES=$(curl -s -w '%{http_code}'  -X PUT -v http://localhost:$SIM_PORT/a1-p/policytypes/2 -H Content-Type:application/json --data-binary @sim_hw.json)
    retcode=$?
    if [ $retcode -eq 0 ]; then
        status=${RES:${#RES}-3}
        if [ $status -ne 201 ]; then
            retcode=1
        fi
    fi

    if [ $retcode -ne 0 ]; then
        echo "Retrying..."
        sleep 1
    fi
done

retcode=1
while [ $retcode -ne 0 ]; do
    echo "Checking that type is available"
    RES=$(curl -s -w '%{http_code}' localhost:$PMS_PORT/a1-policy/v2/rics)
    retcode=$?
    if [ $retcode -eq 0 ]; then
        if [[ "$RES" != *'"policytype_ids":["2"]'* ]]; then
            retcode=1
        fi
    fi
    if [ $retcode -ne 0 ]; then
        echo "Retrying..."
        sleep 1
    fi
done
