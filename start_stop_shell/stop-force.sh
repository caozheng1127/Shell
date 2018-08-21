#!/bin/sh
echo 'start to stop jarname'
ps -ef | grep -i jarname.jar | grep $USER | grep -v 'grep' | awk '{print $2}' | while read pid
do
	echo "kill pid $pid"
	kill -9 $pid
done
echo 'jarname stoped !'