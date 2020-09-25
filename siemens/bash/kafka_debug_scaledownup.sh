#this is for kafka to debug,need to scale down kafka and zookeeper to 0 ,and wait for 15 minutes ,then scale up to 3.
DAT_REF="2020-09-25"
START_TIME_REF="16:45:00"
END_TIME_REF="17:00:00"
DAT=$(date +%F)
echo "start to scale down and up"
if [ $DAT == $DAT_REF ];then
	while true;do
		START_TIME=$(date +%T)
		if [ $START_TIME == $START_TIME_REF ];then
			echo "start shutdown at [$(date)]" >> 1.log
			kubectl -n kafka-p-fl4fh scale statefulset kafka-p-fl4fh-zookeeper --replicas=0
			kubectl -n kafka-p-fl4fh scale statefulset kafka-p-fl4fh --replicas=0
			echo "shutdown done at [$(date)]" >> 1.log
			while true;do
				kubectl -n kafka-p-fl4fh get pod |grep 'Terminating'|grep '0/2'
				if [ $? -eq 0 ];then
					echo "Terminating done at [$(date)]" >> 1.log
					break
				fi
			done
			break
		fi
	done
	while true;do
		END_TIME=$(date +%T)
		if [ $END_TIME == $END_TIME_REF ];then
			echo "startup at [$(date)]" >> 1.log
			kubectl -n kafka-p-fl4fh scale statefulset kafka-p-fl4fh-zookeeper --replicas=3
			kubectl -n kafka-p-fl4fh scale statefulset kafka-p-fl4fh --replicas=3
			echo "startup done at [$(date)]" >> 1.log
			while true;do
			  count=$(kubectl -n kafka-p-fl4fh get pod|grep kafka-p-fl4fh-[0-2]|grep 2/2|wc -l)
			  if [ $count -eq 3 ];then
				  echo "all kafka running at [$(date)]" >> 1.log
				  break
			  fi
			done
			break
		fi
	done
	kubectl -n kafka-p-fl4fh get pod -o wide -w
fi
