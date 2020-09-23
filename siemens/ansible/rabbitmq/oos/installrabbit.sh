#!/usr/bin/env bash
TemplateName=$TemplateName
oos_role=$oos_role
region=$region
tag_key=$tag_key
tag_value=$tag_value
oss_bucket=$oss_bucket
object_key=$object_key


#count=`./aliyun oos ListTemplates|jq .Templates[].TemplateName|grep $TemplateName|wc -l`
#if [ $count -ne 0 ];then
echo "delete template"
./aliyun oos DeleteTemplate --TemplateName $TemplateName --region $region || true
#fi

Content=`awk 'BEGIN{ORS=" "}{print $0}'  ${TemplateName}.json`
echo $Content
echo "create template"
echo "./aliyun oos CreateTemplate --region $region --TemplateName $TemplateName --Content $Content"|bash
echo "excute template"
./aliyun oos StartExecution --TemplateName $TemplateName --RegionId $region --Parameters '{ "oss_bucket":"'$oss_bucket'","object_key":"'$object_key'","OOSAssumeRole":"'$oos_role'","targets":{"Type":"Tags","Tags":[{"Key":"'$tag_key'","Value":"'$tag_value'"}]} }'
