ARG REDIS_VERSION
FROM redis:${REDIS_VERSION}

LABEL maintainer="kyan8897@163.com"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENV QUORUM 2
ENV DOWN_AFTER 30000
ENV PARALLEL_SYNCS 1
ENV FAILOVER_TIMEOUT 180000
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "entrypoint.sh" ]

EXPOSE 26379