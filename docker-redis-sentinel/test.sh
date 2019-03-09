!#/usr/bin/env bash
echo ------------------Run test------------------------
docker-compose up -d --build --scale slave=2

echo ----------Check the status of cluster-------------
docker-compose ps

echo ------------------Check IP------------------------
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q)

echo --------------Check sentinel info ----------------
docker exec docker-redis-sentinel_sentinel_1 redis-cli -p 26379 info sentinel

echo ------------------Current master------------------
docker exec docker-redis-sentinel_sentinel_1 redis-cli -p 26379 sentinel get-master-addr-by-name mymaster

echo -----------Simulate automatic failover------------
echo ------------------Pause master--------------------
docker-compose pause master

echo --------------Waiting 10sec for failover----------
sleep 10

echo --------------Check sentinel info ----------------
docker exec docker-redis-sentinel_sentinel_1 redis-cli -p 26379 info sentinel

echo ------------------Current master------------------
docker exec docker-redis-sentinel_sentinel_1 redis-cli -p 26379 sentinel get-master-addr-by-name mymaster

echo ------------------Test finished------------------
docker-compose down
