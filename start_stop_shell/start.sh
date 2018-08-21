#!/bin/sh
cd /home/username/jarname

sh run.sh
sleep 2
tail -f ./logs/svr_data.log ./logs/jarname.log