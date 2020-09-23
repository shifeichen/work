#!/usr/bin/env python
#coding=utf-8

from aliyunsdkcore.auth.credentials import EcsRamRoleCredential
from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkpvtz.request.v20180101.AddZoneRecordRequest import AddZoneRecordRequest
from aliyunsdkpvtz.request.v20180101.DescribeZoneInfoRequest import DescribeZoneInfoRequest

import socket
hostname=socket.gethostname()
ip=socket.gethostbyname(hostname)
ip_array=ip.split('.')
record=ip_array[3]+'.'+ip_array[2]

import sys
if(len(sys.argv) != 4):
  print("usage: "+sys.argv[0]+" zone_id reverse_zone_id role_name")
  exit(1)
else:
  zone_id = sys.argv[1]
  reverse_zone_id = sys.argv[2]
  role_name = sys.argv[3]


print("hostname="+hostname)
print("ip="+ip)
print("record="+record)
print("zone_id="+zone_id)
print("reverse_zone_id="+reverse_zone_id)

credential=EcsRamRoleCredential(role_name)
client = AcsClient(credential=credential)

# get zone name from zone_id
request = DescribeZoneInfoRequest()
request.set_accept_format('json')
request.set_ZoneId(zone_id)
response = client.do_action_with_exception(request)

import json
json = json.loads(response)
domain_name = json["ZoneName"]
print("domain_name="+domain_name)

request = AddZoneRecordRequest()
request.set_accept_format('json')

# Each of them is a separate try, otherwise it will be skipped
try:
  # add host and A record for zone
  # add  @  A record to private zone
  request.set_ZoneId(zone_id)
  request.set_Rr("@")
  request.set_Type("A")
  request.set_Value(ip)
  response = client.do_action_with_exception(request)
  print(response)
except ServerException as e:
  if e.error_code == "Record.Invalid.Conflict":
    print(e.get_error_msg())
  else:
    raise ServerException

try:
  # add host A record to private zone
  request.set_Rr(hostname)
  response = client.do_action_with_exception(request)
  print(response)

except ServerException as e:
  if e.error_code == "Record.Invalid.Conflict":
    print(e.get_error_msg())
  else:
    raise ServerException

try:
  # add ptr records
  request.set_ZoneId(reverse_zone_id)
  request.set_Rr(record)
  request.set_Type("PTR")
  request.set_Value(hostname+"."+domain_name)
  response = client.do_action_with_exception(request)
  print(response)

except ServerException as e:
  if e.error_code == "Record.Invalid.Conflict":
    print(e.get_error_msg())
  else:
    raise ServerException