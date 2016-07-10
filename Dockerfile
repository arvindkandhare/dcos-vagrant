FROM java:8

MAINTAINER Arvind Kandhare (arvind.kandhare@emc.com)

COPY distributedlog-service /opt/distributedlog-service/


EXPOSE 7000

CMD ["opt/distributedlog-service/bin/dlog", "local", "7000", "3"]
