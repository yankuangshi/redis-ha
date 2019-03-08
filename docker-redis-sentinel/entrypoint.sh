#!/bin/sh

# create redis-sentinel configuration
# for redis-sentinel complete configuration can be downloaded from http://download.redis.io/redis-stable/sentinel.conf
SENTINEL_CONFIG_FILE=/etc/redis-sentinel.conf

DEFAULT_SENTINEL_PORT=26379
DEFAULT_REDIS_PORT=6379

echo "port $DEFAULT_SENTINEL_PORT" >> $SENTINEL_CONFIG_FILE
echo "dir /tmp" >> $SENTINEL_CONFIG_FILE
echo "sentinel monitor $MASTER_NAME $MASTER $DEFAULT_REDIS_PORT $QUORUM" >> $SENTINEL_CONFIG_FILE
echo "sentinel down-after-milliseconds $MASTER_NAME $DOWN_AFTER" >> $SENTINEL_CONFIG_FILE
echo "sentinel failover-timeout $MASTER_NAME $FAILOVER_TIMEOUT" >> $SENTINEL_CONFIG_FILE
echo "sentinel parallel-syncs $MASTER_NAME $PARALLEL_SYNCS" >> $SENTINEL_CONFIG_FILE

# for verify
cat $SENTINEL_CONFIG_FILE >> /etc/redis-sentinel.conf.bak

exec redis-server $SENTINEL_CONFIG_FILE --sentinel