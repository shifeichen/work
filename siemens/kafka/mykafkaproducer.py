from kafka import KafkaProducer
import time
#yum install python3
#pip3 install kafka-python
hosts='kafka.mdsp-bk-kafka:9092'
# producer = KafkaProducer(bootstrap_servers=['134.244.231.98:9092','134.244.231.231:9092'])
producer = KafkaProducer(bootstrap_servers=hosts)
while True:
    time.sleep(1)
    message=time.ctime().encode()+b"test message"
    producer.send('testTopic', key=b'foo', value=message)
