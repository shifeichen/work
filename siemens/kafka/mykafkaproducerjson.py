from kafka import KafkaProducer
import time
import json
#yum install python3
#pip3 install kafka-python
# hosts='kafka.mdsp-bk-kafka:9092'
producer = KafkaProducer(value_serializer=lambda v: json.dumps(v).encode('utf-8'),bootstrap_servers=['134.244.231.98:9092','134.244.231.231:9092'])
# producer = KafkaProducer(bootstrap_servers=hosts)
count=0
data_json={}
with open('message.json','r',encoding='utf8') as f:
    data_str=f.read()
    data_json=json.loads(data_str)

while True:
    count+=1
    time.sleep(1)
    producer.send('testTopic', data_json)
