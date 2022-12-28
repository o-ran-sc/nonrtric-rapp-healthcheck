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

docker network create nonrtric-docker-net

DIR="$( cd "$( dirname "$0" )" && pwd )"

docker run --detach --rm -v $DIR/application_configuration.json:/opt/app/policy-agent/data/application_configuration.json -p 8081:8081 -p 8433:8433 --network=nonrtric-docker-net --name=policy-agent-container nexus3.o-ran-sc.org:10002/o-ran-sc/nonrtric-plt-a1policymanagementservice:2.5.0

docker run --detach --rm -p 8085:8085 -p 8185:8185 -e A1_VERSION=OSC_2.1.0 -e ALLOW_HTTP=true --network=nonrtric-docker-net --name=ric1 nexus3.o-ran-sc.org:10002/o-ran-sc/a1-simulator:2.3.1

docker run --detach --rm -p 8086:8085 -p 8186:8185 -e A1_VERSION=STD_1.1.3 -e ALLOW_HTTP=true --network=nonrtric-docker-net --name=ric2 nexus3.o-ran-sc.org:10002/o-ran-sc/a1-simulator:2.3.1

sleep 1

curl -X PUT -v http://localhost:8085/a1-p/policytypes/2 -H Content-Type:application/json --data-binary @sim_hw.json
