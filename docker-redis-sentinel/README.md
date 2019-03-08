Docker-Redis-Sentinel
====
该项目利用`docker-compose`编排一个Redis的哨兵（[Sentinel][1]）集群

服务说明
---
[docker-compose.yml][2]文件中定义了3个服务：

* master：Redis主节点服务
* slave：Redis从节点服务
* sentinel：Redis哨兵服务

Dockerfile
---
使用[Dockerfile][3]定制了启动redis哨兵节点的镜像，其中通过[entrypoint.sh][4]脚本生成sentinel的配置文件

通过查看redis-sentinel的[原始配置文档][5]可以发现sentinel的配置很简单：

```sh
port 26379
dir /tmp
sentinel monitor {master_name} {master_ip} {master_port} {quorum}
sentinel down-after-milliseconds {master_name} {time}
sentinel parallel-syncs {master_name} {number}
sentinel failover-timeout {master_name} {time}
```

其中：
* `sentinel monitor {master_name} {master_ip} {master_port} {quorum}` 

    监控地址端口为{master_ip}:{master_port}的这个主节点，并且命名为{master_name}（如该项目中命名为mymaster），最后的{quorum}（默认为2）和主节点的故障判定有关：
    至少需要2个哨兵节点的同意，才能判定主节点故障并且开始故障转移，建议取值为哨兵数量的一半加1。

* `sentinel down-after-milliseconds {master_name} {time}`

    哨兵使用ping命令对其他节点进行心跳检测，如果其他节点超过down-after-milliseconds配置的时间没有回复，
    将其进行主观下线，该配置对主节点、从节点和哨兵节点的主观下线判定都有效

* `sentinel parallel-syncs {master_name} {number}`

    它规定了新的主节点向从节点同时发起主从复制的从节点的个数。{number}取值越大，从节点完成复制的时间越快，但是对主节点的网络负载、硬盘负载造成的压力也越大

* `sentinel failover-timeout {master_name} {time}`

    failover-timeout与故障转移超时的判断有关，但是该参数不是用来判断整个故障转移阶段的超时，而是其几个子阶段的超时，例如如果从节点晋升主节点时间超过timeout，或从节点向新的主节点发起复制操作的时间（不包括复制数据的时间）超过timeout，都会导致故障转移超时失败

以上几个重要配置都在`Dockerfile`中做了默认的配置：

```sh
ENV QUORUM 2                #默认至少需要2个哨兵节点的同意才能判定故障
ENV DOWN_AFTER 30000        #默认配置30秒
ENV PARALLEL_SYNCS 1        #默认同时只能向1个从节点发起主从复制
ENV FAILOVER_TIMEOUT 180000 #默认配置180秒
```

基础镜像
---
Redis镜像的版本在`env.sample`中做了定义，使用的是redis apline镜像

[redis:<version>镜像和redis:<version>-alpine镜像的区别][6]
 
实用操作
---

* 创建镜像并且启动容器

```sh
$ cp env.sample .env
$ docker-compose up --build -d
...
Creating docker-redis-sentinel_master_1 ... done
Creating docker-redis-sentinel_slave_1    ... done
Creating docker-redis-sentinel_sentinel_1 ... done
```

该命令默认启动：1个Redis主节点、1个Redis从节点、1个Redis哨兵节点

* 查看容器状态

```sh
$ docker-compose ps
              Name                            Command               State          Ports
-----------------------------------------------------------------------------------------------
docker-redis-sentinel_master_1     docker-entrypoint.sh redis ...   Up      6379/tcp
docker-redis-sentinel_sentinel_1   entrypoint.sh                    Up      26379/tcp, 6379/tcp
docker-redis-sentinel_slave_1      docker-entrypoint.sh redis ...   Up      6379/tcp
```

* 添加哨兵节点和从节点

```sh
$ docker-compose scale sentinel=3 slave=3
$ docker-compose ps
              Name                            Command               State          Ports
-----------------------------------------------------------------------------------------------
docker-redis-sentinel_master_1     docker-entrypoint.sh redis ...   Up      6379/tcp
docker-redis-sentinel_sentinel_1   entrypoint.sh                    Up      26379/tcp, 6379/tcp
docker-redis-sentinel_sentinel_2   entrypoint.sh                    Up      26379/tcp, 6379/tcp
docker-redis-sentinel_sentinel_3   entrypoint.sh                    Up      26379/tcp, 6379/tcp
docker-redis-sentinel_slave_1      docker-entrypoint.sh redis ...   Up      6379/tcp
docker-redis-sentinel_slave_2      docker-entrypoint.sh redis ...   Up      6379/tcp
docker-redis-sentinel_slave_3      docker-entrypoint.sh redis ...   Up      6379/tcp
```

也可以在容器启动时通过参数`--scale`来指定数量

```sh
$ docker-compose up --build -d --scale sentinel=3 --scale slave=3
```


* 查看容器运行日志 `docker logs -ft #container_name`

```sh
$ docker logs -ft docker-redis-sentinel_sentinel_1
```

* 获取哨兵信息

```sh
$ docker exec docker-redis-sentinel_sentinel_1 redis-cli -p 26379 info sentinel
sentinel_masters:1
sentinel_tilt:0
sentinel_running_scripts:0
sentinel_scripts_queue_length:0
sentinel_simulate_failure_flags:0
master0:name=mymaster,status=ok,address=192.168.160.2:6379,slaves=1,sentinels=1
```

* 获取监控的主节点mymaster的地址信息

```sh
$ docker exec docker-redis-sentinel_sentinel_1 redis-cli -p 26379 sentinel get-master-addr-by-name mymaster
192.168.160.2
6379
```

其余Sentinel相关的API可以查看该[文档][7]



[1]: https://redis.io/topics/sentinel
[2]: https://github.com/yankuangshi/redis-ha/blob/master/docker-redis-sentinel/docker-compose.yml
[3]: https://github.com/yankuangshi/redis-ha/blob/master/docker-redis-sentinel/Dockerfile
[4]: https://github.com/yankuangshi/redis-ha/blob/master/docker-redis-sentinel/entrypoint.sh
[5]: http://download.redis.io/redis-stable/sentinel.conf
[6]: https://hub.docker.com/_/redis#image_variants
[7]: https://redis.io/topics/sentinel#sentinel-api