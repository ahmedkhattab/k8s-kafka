# Dockerfile for running a Kafka ensemble (primarily in Kubernetes)
# - Apache Kafka 0.8.1.1 from binary distribution.
# - Oracle Java 7 and a base of Ubuntu 12.04, currently.
#

FROM relateiq/oracle-java7

MAINTAINER Graeme Johnson <graeme@johnson-family.ca>

RUN \
  mkdir /kafka /data /logs && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates

ENV KAFKA_RELEASE_ARCHIVE kafka_2.10-0.8.1.1.tgz

# Download Kafka binary distribution
RUN \
  wget https://dist.apache.org/repos/dist/release/kafka/0.8.1.1/${KAFKA_RELEASE_ARCHIVE} && \
  tar -zx -C /kafka --strip-components=1 -f ${KAFKA_RELEASE_ARCHIVE} && \
  rm -rf kafka_* && \
  wget http://repo1.maven.org/maven2/org/slf4j/slf4j-log4j12/1.7.6/slf4j-log4j12-1.7.6.jar -P /kafka/libs

ADD config /kafka/config
ADD config-and-run.sh /kafka/

# Set up a user to run Kafka
RUN groupadd kafka && \
  useradd -d /kafka -g kafka -s /bin/false kafka && \
  chown -R kafka:kafka /kafka /data /logs
USER kafka
ENV PATH /kafka/bin:$PATH
WORKDIR /kafka

# primary, jmx
EXPOSE 9092 7203

VOLUME [ "/data", "/logs" ]

ENTRYPOINT ["/kafka/config-and-run.sh"]
CMD [""]
