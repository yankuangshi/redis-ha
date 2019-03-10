#!/usr/bin/env bash

# Script demo for creating redis cluster with redis4.0

# redis cluster minimum config
# port 6379
# cluster-enabled yes
# cluster-config-file nodes.conf
# cluster-node-timeout 5000
# appendonly yes

# define images
redis_image='redis:4.0-alpine'
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

echo $cluster_hosts
# echo $cluster_hosts
echo ------Create redis cluster----------

trib_cmd='ruby redis-trib.rb create --replicas 1 '$cluster_hosts

echo $trib_cmd
echo $PWD

# Important thing here is to add the ruby container into ‘red_cluster’ network, 
# otherwise it will not be able to access Redis containers via their IP addresses.
echo 'yes' | docker run -i --rm -v $PWD/redis-trib.rb:/redis-trib.rb --net $network_name ruby sh -c '\
    gem install redis \
    && ruby redis-trib.rb create --replicas 1 '"$cluster_hosts"
