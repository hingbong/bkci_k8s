#! /bin/sh
mkdir -p /data/docker/bkci/ci/backend/resources
mkdir -p /data/docker/bkci/ci/backend/logs

consul kv get -http-addr=consul-ui config/application:dev/data > resources/application.yaml
consul kv get -http-addr=consul-ui config/dockerhostci:dev/data > resources/dockerhost.yaml

# build init.sh to hosted which will be used in container
hosts=$(ping -c 1 $BKCI_FQDN|head -1|egrep -o "([0-9]{1,3}.){3}[0-9]{1,3}")
hosts="$hosts $BKCI_FQDN"
template=$(cat /base/init.sh) && echo "${template/__hosts__/$hosts}" > /data/docker/bkci/ci/agent-package/script/init.sh

# cp jdk to hosted whick will be used in container
cp -r /base/jdk /data/docker/bkci/public/ci/docker/apps/

java  \
    -server \
    -Xloggc:logs/gc.log \
    -XX:NewRatio=1 \
    -XX:SurvivorRatio=8 \
    -XX:+PrintTenuringDistribution \
    -XX:+PrintGCDetails \
    -XX:+PrintGCDateStamps \
    -XX:+UseConcMarkSweepGC \
    -XX:+HeapDumpOnOutOfMemoryError \
    -XX:HeapDumpPath=oom.hprof \
    -XX:ErrorFile=error_sys.log \
    -Dspring.profiles.active=dev\
    -Dservice.log.dir=logs/ \
    -Dsun.jnu.encoding=UTF-8 \
    -Dfile.encoding=UTF-8 \
    -Dservice-suffix=ci \
    -Ddevops_gateway=$BKCI_FQDN \
    -Dspring.cloud.config.enabled=false \
    -Dspring.config.location=resources/application.yaml,resources/dockerhost.yaml,classpath:/application.yml \
    -Dspring.main.allow-bean-definition-overriding=true \
    -Dspring.cloud.consul.enabled=false \
    -jar boot-dockerhost.jar