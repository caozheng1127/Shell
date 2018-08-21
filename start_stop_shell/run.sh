#!/bin/sh
export JAVA_HOME=/usr/local/jdk1.8.0_91
echo "1"
mkdir -p ./logs
echo "2"
GCLOGPATH=./logs/gc.log
HEAPDUMPLOGPATH=./logs/heap_dump
SVRLOGPATH=./logs/svr_data.log
echo "3"
nohup "$JAVA_HOME"/bin/java -jar -server -Xms256m -Xmx256m -Xss256k -XX:+UseParallelGC -XX:+UseParallelOldGC -verbose:gc -Xloggc:$GCLOGPATH -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=100M -XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -XX:HeapDumpPath=$HEAPDUMPLOGPATH -XX:OnError="kill -3 <pid>" -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=48795  jarname.jar </dev/null>>$SVRLOGPATH 2>&1 &