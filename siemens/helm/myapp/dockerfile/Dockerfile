FROM openjdk:11
MAINTAINER chenshifei
LABEL maintaineremail="252509628@qq.com"
ENV S3_VERSION 5.5.2

ENV JAVA_HOME /usr/local/openjdk-11
ENV S3_PLUGIN confluentinc-kafka-connect-s3-${S3_VERSION}
ENV BASE_DIR /usr/local/

ENV KAFKA_DIR /usr/local/kafka_2.13-2.5.0

ADD https://archive.apache.org/dist/kafka/2.5.0/kafka_2.13-2.5.0.tgz $BASE_DIR
RUN tar xf $BASE_DIR/kafka_2.13-2.5.0.tgz -C $BASE_DIR/ && rm -f $BASE_DIR/kafka_2.13-2.5.0.tgz
RUN ls $BASE_DIR/
RUN ln -s $KAFKA_DIR /usr/local/kafka
RUN mkdir /usr/local/kafka/plugins

ADD https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-s3/versions/${S3_VERSION}/confluentinc-kafka-connect-s3-${S3_VERSION}.zip /
RUN unzip /confluentinc-kafka-connect-s3-${S3_VERSION}.zip -d /usr/local/kafka/plugins  && rm -f /confluentinc-kafka-connect-s3-${S3_VERSION}.zip
#directly mount to file path $KAFKA_DIR/config/connect-distributed.properties in deployment yaml file
#TEST
#ADD connect-distributed.properties $KAFKA_DIR/config
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
WORKDIR /usr/local/kafka
EXPOSE 8083
USER root
#cover cmd in deployment yaml
CMD ["/bin/bash", "-c" ,"/entrypoint.sh"]
