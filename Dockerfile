###
## Forked from  dylanmei/docker-zeppelin with customizations
## Melvin Ramos 01.04.2017
## I added Cassandra and other modules
## I added R Libs, but not other RLibs, we need to look at that later.
## I added customs properties for ElasticSearch on Spark, so it gets those fired up by Zeppelin.  
## As of this writing, Zeppelin Interpreter for ES is not ready as it is supporing <5.0+ version.
###

FROM gettyimages/spark:2.0.2-hadoop-2.7

ENV DEBIAN_FRONTEND=noninteractive

# SciPy
RUN set -ex \
 && buildDeps=' \
    libpython3-dev \
    build-essential \
    pkg-config \
    gfortran \
 ' \
 && apt-get update && apt-get install -y --no-install-recommends \
    $buildDeps \
    ca-certificates \
    wget \
    liblapack-dev \
    libopenblas-dev \
 && packages=' \
    numpy \
    pandasql \
    scipy \
 ' \
 && pip3 install $packages \
 && apt-get purge -y --auto-remove $buildDeps \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update 
RUN apt-get install -y vim --assume-yes
RUN apt-get install -y curl --assume-yes

RUN apt-get update
RUN apt-get install -y  r-base --assume-yes
#TODO: See if this is needed..... Melvin Ramos
#RUN `R -e "install.packages('devtools', repos = 'http://cran.us.r-project.org')"`
#RUN `R -e "install.packages('knitr', repos = 'http://cran.us.r-project.org')"`
#RUN `R -e "install.packages('ggplot2', repos = 'http://cran.us.r-project.org')"`
#RUN `R -e "install.packages(c('devtools','mplot', 'googleVis'), repos = 'http://cran.us.r-project.org'); require(devtools); install_github('ramnathv/rCharts')"`


# Zeppelin
ENV ZEPPELIN_PORT 8080
ENV ZEPPELIN_HOME /usr/zeppelin
ENV ZEPPELIN_CONF_DIR $ZEPPELIN_HOME/conf
ENV ZEPPELIN_NOTEBOOK_DIR $ZEPPELIN_HOME/notebook
ENV ZEPPELIN_COMMIT 7f6f739ae396e07de573bea4ef16a388c54e77b8
RUN set -ex \
 && buildDeps=' \
    git \
    bzip2 \
 ' \
 && apt-get update && apt-get install -y --no-install-recommends $buildDeps \
 && curl -sL http://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
   | gunzip \
   | tar x -C /tmp/ \
 && git clone https://github.com/apache/zeppelin.git /usr/src/zeppelin \
 && cd /usr/src/zeppelin \
 && git checkout -q $ZEPPELIN_COMMIT \
 && dev/change_scala_version.sh "2.11" \
 && MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=1024m" /tmp/apache-maven-3.3.9/bin/mvn --batch-mode package -DskipTests -Pscala-2.11 -Pbuild-distr \
  -pl 'zeppelin-interpreter,zeppelin-zengine,zeppelin-display,spark-dependencies,spark,markdown,cassandra,flink,file,ignite,angular,shell,hbase,postgresql,jdbc,python,elasticsearch,zeppelin-web,zeppelin-server,zeppelin-distribution' \
 && tar xvf /usr/src/zeppelin/zeppelin-distribution/target/zeppelin*.tar.gz -C /usr/ \
 && mv /usr/zeppelin* $ZEPPELIN_HOME \
 && mkdir -p $ZEPPELIN_HOME/logs \
 && mkdir -p $ZEPPELIN_HOME/run \
 && apt-get purge -y --auto-remove $buildDeps \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/src/zeppelin \
 && rm -rf /root/.m2 \
 && rm -rf /root/.npm \
 && rm -rf /tmp/*

ADD about.json $ZEPPELIN_NOTEBOOK_DIR/2BTRWA9EV/note.json
ADD spark-defaults.conf /usr/spark-2.0.2/conf/spark-defaults.conf


WORKDIR $ZEPPELIN_HOME
CMD ["bin/zeppelin.sh"]
