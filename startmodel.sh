#!/bin/sh

DIRNAME=`dirname $0`
RUNHOME=`cd $DIRNAME;pwd`

APP_PACKAGE=`basename $RUNHOME/*.war`
APP_NAME=`echo $APP_PACKAGE | sed -r 's/-((v|V)|[0-9])(.*).war//g'`
APP_PORT=8085

JAVA="$JAVA_HOME/bin/java"
JAVA_OPTS="-Xms256M -Xmx2048M -Djava.security.egd=file:/dev/./urandom"
export JAVA_OPTS=$JAVA_OPTS

create_kafka_topic()
{
   KAFKA_ZK=$OPENPALETTE_KAFKA_ZOOKEEPER_ADDRESS:$OPENPALETTE_KAFKA_ZOOKEEPER_PORT
   $JAVA -jar kafka-topic-manager-09-0.1-snapshot.jar -z $KAFKA_ZK -t "udpspan"
   $JAVA -jar kafka-topic-manager-09-0.1-snapshot.jar -z $KAFKA_ZK -t "udpstat"
}

init_tomcat()
{	
    cp -r /home/apache-tomcat-* /home/collector/tomcat
	rm -f /home/collector/tomcat/conf/server.xml
	cp -f /home/collector/server.xml /home/collector/tomcat/conf

	unzip -o -q -d /home/collector/tomcat/webapps/ROOT $APP_PACKAGE
}

start_app()
{
	$RUNHOME/tomcat/bin/catalina.sh run &
}


modify_properties()
{
	#check_service_version smartsight-hbase

	if [ ! -z "$PUBLISH_PORT" ];then
		sed -i "s/hbase.client.host=.*/hbase.client.host=$OPENPALETTE_MSB_IP/" $RUNHOME/tomcat/webapps/ROOT/WEB-INF/classes/hbase.properties
		sed -i "s/hbase.client.port=.*/hbase.client.port=$PUBLISH_PORT/" $RUNHOME/tomcat/webapps/ROOT/WEB-INF/classes/hbase.properties
	fi

	sed -i "s/cluster.zookeeper.address=.*/cluster.zookeeper.address=$OPENPALETTE_KAFKA_ZOOKEEPER_ADDRESS/" $RUNHOME/tomcat/webapps/ROOT/WEB-INF/classes/pinpoint-collector.properties
	sed -i "s/collector.kafka.consumer.zk=.*/collector.kafka.consumer.zk=$OPENPALETTE_KAFKA_ZOOKEEPER_ADDRESS:$OPENPALETTE_KAFKA_ZOOKEEPER_PORT/" $RUNHOME/tomcat/webapps/ROOT/WEB-INF/classes/pinpoint-collector.properties

	sed -i "s/collector.kafka.ip=.*/collector.kafka.ip=$OPENPALETTE_KAFKA_ADDRESS/" $RUNHOME/tomcat/webapps/ROOT/WEB-INF/classes/pinpoint-collector.properties
	sed -i "s/collector.kafka.port=.*/collector.kafka.port=$OPENPALETTE_KAFKA_PORT/" $RUNHOME/tomcat/webapps/ROOT/WEB-INF/classes/pinpoint-collector.properties

	sed -i "s/collector.kafka.zk.ip=.*/collector.kafka.zk.ip=$OPENPALETTE_KAFKA_ZOOKEEPER_ADDRESS/" $RUNHOME/tomcat/webapps/ROOT/WEB-INF/classes/pinpoint-collector.properties
    sed -i "s/collector.kafka.zk.port=.*/collector.kafka.zk.port=$OPENPALETTE_KAFKA_ZOOKEEPER_PORT/" $RUNHOME/tomcat/webapps/ROOT/WEB-INF/classes/pinpoint-collector.properties
}

create_kafka_topic
init_tomcat
modify_properties
start_app
