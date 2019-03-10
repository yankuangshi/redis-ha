#!/usr/bin/env bash

# Script demo for creating redis cluster with redis5.0

# redis cluster minimum config
# port 6379
# cluster-enabled yes
# cluster-config-file nodes.conf
# cluster-node-timeout 5000
# appendonly yes

# define images
redis_image='redis:5.0-alpine'
ruby_image='ruby'
# start command with redis cluster enabled
start_cmd='redis-server --port 6379 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes'
# define docker network
network_name='red_cluster_net'


echo --------Create docker network--------
docker network create $network_name

echo -----Create redis cluster nodes------
for index in `seq 1 6`; do \
    docker run -d --rm \
    --name "redis-$index" \
    --net $network_name \
    $redis_image $start_cmd; \
    echo "cluster node redis-$index created"
done

cluster_hosts=''
# get all cluster nodes IP 
for index in `seq 1 6`; do \
    hostip=`docker inspect -f '{{(index .NetworkSettings.Networks "'$network_name'").IPAddress}}' "redis-$index"`;
    echo "IP for cluster node redis-$index is: " $hostip
    cluster_hosts="$cluster_hosts$hostip:6379 ";
done

# echo $cluster_hosts
echo ------Create redis cluster----------
echo 'yes' | docker run -i --rm --net $network_name $redis_image redis-cli --cluster create $cluster_hosts --cluster-replicas 1;