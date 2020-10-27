#this is for kafka to debug,need to scale down kafka and zookeeper to 0 ,and wait for 15 minutes ,then scale up to 3.
echo "--------------------------------------------------------------------------" >>1.log
DAT_REF="2020-10-27"
START_TIME_REF="14:30:00"
END_TIME_REF="14:45:00"
DAT=$(date +%F)
echo "start to scale down and up"
if [ $DAT == $DAT_REF ];then
	while true;do
		START_TIME=$(date +%T)
		if [ $START_TIME == $START_TIME_REF ];then
			echo "start shutdown at [$(date)]" >> 1.log
			kubectl --kubeconfig /d/config/local-rancher.txt -n mdsp-bk-kafka scale statefulset kafka-zookeeper --replicas=0
			kubectl --kubeconfig /d/config/local-rancher.txt -n mdsp-bk-kafka scale statefulset kafka --replicas=0
			echo "shutdown done at [$(date)]" >> 1.log
			while true;do
				kubectl --kubeconfig /d/config/local-rancher.txt -n mdsp-bk-kafka get pod |grep 'Terminating'|grep '0/2'
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
			kubectl --kubeconfig /d/config/local-rancher.txt -n mdsp-bk-kafka scale statefulset kafka-zookeeper --replicas=3
			kubectl --kubeconfig /d/config/local-rancher.txt -n mdsp-bk-kafka scale statefulset kafka --replicas=3
			echo "startup done at [$(date)]" >> 1.log
			while true;do
			  count=$(kubectl --kubeconfig /d/config/local-rancher.txt -n mdsp-bk-kafka get pod|grep kafka-[0-2]|grep 2/2|wc -l)
			  if [ $count -eq 3 ];then
				  echo "all kafka running at [$(date)]" >> 1.log
				  break
			  fi
			done
			break
		fi
	done
	kubectl --kubeconfig /d/config/local-rancher.txt -n mdsp-bk-kafka get pod -o wide
	cat 1.log
fi
