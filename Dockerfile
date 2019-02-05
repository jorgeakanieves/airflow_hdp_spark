FROM python:3.6-slim
MAINTAINER Jorge Nieves

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.9.0
ARG AIRFLOW_HOME=/usr/local/airflow

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

# java
RUN apt-get update && apt-get install -y wget sudo vim procps curl iputils-ping
RUN curl -LOb "oraclelicense=a" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
RUN tar xvf jdk-8u131-linux-x64.tar.gz
RUN mkdir -p /usr/lib/jvm && mv jdk1.8.0_131 /usr/lib/jvm/java-8-openjdk-amd64
RUN update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-8-openjdk-amd64/bin/java 1
RUN update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-8-openjdk-amd64/bin/javac 1


RUN set -ex \
    && buildDeps=' \
        python3-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        python3-pip \
        python3-requests \
        mysql-client \
        mysql-server \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
	&& useradd -ms /bin/bash -d ${AIRFLOW_HOME} -p $(openssl passwd -1 airflow) airflow \
    && usermod -a -G sudo airflow \
    && echo "airflow ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && pip install -U pip setuptools wheel \
	&& pip install -U pip setuptools wheel \
    && pip install psycopg2-binary \
    && pip install Cython \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql]==$AIRFLOW_VERSION \
    && pip install celery[redis]==4.1.1 \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow:airflow ${AIRFLOW_HOME}

EXPOSE 8091 5555 8793

WORKDIR ${AIRFLOW_HOME}
ARG SPARK_HOME=/usr/local/spark
ARG HADOOP_HOME=/usr/local/hadoop
RUN wget https://archive.apache.org/dist/spark/spark-2.3.1/spark-2.3.1-bin-hadoop2.7.tgz \
    && apt-get --purge remove -y wget \
    && tar -xvzf spark-2.3.1-bin-hadoop2.7.tgz \
    && mv spark-2.3.1-bin-hadoop2.7 /usr/local/spark \
    && rm spark-2.3.1-bin-hadoop2.7.tgz \
    && chown airflow:airflow -R /usr/local/spark

RUN set -x \
    && curl -fSL "https://archive.apache.org/dist/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz" -o /tmp/hadoop.tar.gz \
    && tar -xvf /tmp/hadoop.tar.gz -C /tmp \
    && mv /tmp/hadoop-2.7.7 /usr/local && mv /usr/local/hadoop-2.7.7 /usr/local/hadoop && rm /tmp/hadoop.tar.gz*
RUN mkdir -p /spark/logs/
RUN chown -R airflow:airflow /spark/logs/
COPY config/hadoop/yarn-site.xml config/hadoop/core-site.xml /usr/local/hadoop/etc/hadoop/
RUN chown airflow:airflow -R /usr/local/hadoop

RUN mkdir -p ${AIRFLOW_HOME}/shared/data-models/exported &&  mkdir -p ${AIRFLOW_HOME}/shared/data-models/traindata && mkdir -p ${AIRFLOW_HOME}/shared/data-models/current
RUN chown -R airflow:airflow ${AIRFLOW_HOME}/shared/data-models

USER airflow

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV SPARK_HOME /usr/local/spark
ENV PATH $PATH:$SPARK_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV SPARK_MASTER local[*]
ENV SPARK_DIST_CLASSPATH /usr/local/hadoop/etc/hadoop/:/usr/local/hadoop/share/hadoop/common/lib/*:/usr/local/hadoop/share/hadoop/common/*:/usr/local/hadoop/share/hadoop/hdfs:/usr/local/hadoop/share/hadoop/hdfs/lib/*:/usr/local/hadoop/share/hadoop/hdfs/*:/usr/local/hadoop/share/hadoop/mapreduce/*:/usr/local/hadoop/share/hadoop/yarn:/usr/local/hadoop/share/hadoop/yarn/lib/*:/usr/local/hadoop/share/hadoop/yarn/*
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop/
ENV HADOOP_HOME /usr/local/hadoop 

# integrate spark-hdp
RUN echo "export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/" >> /usr/local/airflow/.bashrc
RUN echo "export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/" >> /usr/local/airflow/.profile
RUN echo HADOOP_HOME=/usr/local/hadoop >> /usr/local/airflow/.bashrc
RUN echo JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh
RUN echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /usr/local/airflow/.bashrc
RUN echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /usr/local/airflow/.profile
RUN echo "export SPARK_HOME=/usr/local/spark" >> /usr/local/airflow/.profile
RUN echo "export SPARK_HOME=/usr/local/spark" >> /usr/local/airflow/.bashrc


WORKDIR ${AIRFLOW_HOME}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"] # set default arg for entrypoint
