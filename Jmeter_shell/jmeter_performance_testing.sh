#! /bin/sh

#引入配置文件
source ./jmeter_config

#配置文件中负载机的数量
NUMBER=$(cat ./jmeter_config|grep -c ip_)

#当前负载机号码
VIS=1

#同步
function sync()
{
	VIS=1
	while (($NUMBER-$VIS))
	do
		#当前用户名
		current_username=$(cat ./jmeter_config|grep username|awk '{a[NR]=$1} END{for(i=1;i<=NR;i++){if(i=="'$VIS'"){printf(a[i])}}}')
		current_username=${current_ip:12}
		#当前ip
		current_ip=$(cat ./jmeter_config|grep ip|awk '{a[NR]=$1} END{for(i=1;i<=NR;i++){if(i=="'$VIS'"){printf(a[i])}}}')
		current_ip=${current_ip:6}
		echo "开始同步$current_ip"
		scp  ~/scp/$jmx_file $current_username@$current_ip:~/apache-jmeter-2.13-benchmark/bin/
		scp  ~/scp/cpifs-jmeter-tool-1.0.0.jar $current_username@$current_ip:~/apache-jmeter-2.13-benchmark/lib/ext
		scp  ~/jmeter.sh $current_username@$current_ip:~/
		#指向下一个负载机
		VIS=`expr $VIS + 1`
	done
}

#启动
function start()
{	
	#用STR配置remote_hosts字段
	STR=$(cat ./jmeter_config|grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][]0-9?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][]0-9?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][]0-9?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][]0-9?)"|awk '{a[NR]=$1} END{for(i=1;i<=NR;i++){printf(","a[i])}}')
	#去掉第一个逗号
	STR=${STR:1}
	VIS=1
	while (($NUMBER+1-$VIS))
	do
		current_username=$(cat ./jmeter_config|grep username|awk '{a[NR]=$1} END{for(i=1;i<=NR;i++){if(i=="'$VIS'"){printf(a[i])}}}')
		current_username=${current_ip:12}
		current_ip=$(cat ./jmeter_config|grep ip|awk '{a[NR]=$1} END{for(i=1;i<=NR;i++){if(i=="'$VIS'"){printf(a[i])}}}')
		current_ip=${current_ip:6}
		echo "启动负载机$current_ip"
		ssh -l $current_username@$current_ip <<remotessh
		nohub sh ~/apache-jmeter-2.13-benchmark/bin/jmeter-server >jmeter-server.log 2>&1 &
		exit
		remotessh
		VIS=`expr $VIS + 1`
	done
	
	echo "结果文件为 $result_jtl"
	echo "修改远程机器IP"
	sed -i 's/remote_hosts=[.,0-9]*/remote_hosts='$STR'/g'  ~/apache-jmeter-2.13-benchmark/bin/jmeter.properties
	echo "远程服务器为:"
	grep -e '^remote_hosts' ~/apache-jmeter-2.13-benchmark/bin/jmeter.properties
	echo "线程数为 $num_threads"
	sed -i 's/ThreadGroup.num_threads">[0-9]*/ThreadGroup.num_threads">'$ThreadGroup_num_threads'/g'  ~/apache-jmeter-2.13-benchmark/bin/$jmx_file
	echo "循环次数为 $loops"
	sed -i 's/LoopController.loops">[0-9]*/LoopController.loops">'$LoopController_loops'/g'  ~/apache-jmeter-2.13-benchmark/bin/$jmx_file
	echo "正在启动远程测试"
	 java -jar  ~/apache-jmeter-2.13-benchmark/bin/ApacheJMeter.jar  -n -t ~/apache-jmeter-2.13-benchmark/bin/$jmx_file  -r -l $result_jtl 
	echo "远程测试结束"
	tail -100f ~/apache-jmeter-2.13-benchmark/bin/$result_jtl
}


#停止
function stop()
{
	VIS=1
	while (($NUMBER+1-$VIS))
	do
		current_username=$(cat ./jmeter_config|grep username|awk '{a[NR]=$1} END{for(i=1;i<=NR;i++){if(i=="'$VIS'"){printf(a[i])}}}')
		current_username=${current_ip:12}
		current_ip=$(cat ./jmeter_config|grep ip|awk '{a[NR]=$1} END{for(i=1;i<=NR;i++){if(i=="'$VIS'"){printf(a[i])}}}')
		current_ip=${current_ip:6}
		echo "停止负载机$current_ip"
		ssh -l $current_username@$current_ip <<remotessh
		pid=$(ps -aux|grep jmeter|grep bootstrap|grep -v grep|awk '{print$2}')
		do
			echo "jmeter is running,to kill bootstrap pid=$pid"
			kill -9 $pid
			echo "kill result: $?"
		done
		exit
		remotessh
	done
}