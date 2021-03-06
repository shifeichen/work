import boto
import boto.s3.connection
import os
import sys
# get normal env
access_key=os.getenv('ceph_access_key')
secret_key=os.getenv('ceph_secret_key')
host=os.getenv('ceph_int_endpoint_uri')
port=os.getenv('ceph_int_endpoint_port')
print("connect information: %s:%s" %(host,port))
if str.isdigit(port):
    port=int(port)
else:
    print("port %s is valid" %port)
bucket_file=sys.argv[1]

#get bucket in configmap that new to be created
bucket_list=[]
with open(bucket_file,'r',encoding='utf-8') as fp:
    for line in fp.readlines():
        bucket_name = line.strip()
        bucket_list.append(bucket_name)

# get all exist bucket
conn = boto.connect_s3(
    aws_access_key_id = access_key,
    aws_secret_access_key = secret_key,
    host = host,
    port = port,
    is_secure=False,
    calling_format = boto.s3.connection.OrdinaryCallingFormat(),
)
old_bucket_list = []
for bucket_obj in conn.get_all_buckets():
    old_bucket_list.append(bucket_obj.name)

#create a new bucket
for bucket_name in bucket_list:
    if bucket_name not in old_bucket_list:
        new_bucket = conn.create_bucket(bucket_name)
        print("create new bucket: %s" %new_bucket.name)
    else:
        print("bucket %s already exist!" %bucket_name)