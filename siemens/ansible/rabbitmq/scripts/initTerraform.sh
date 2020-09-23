#!/bin/bash

# Select ALICLOUD ACCOUNTS to create the infrastructure
if [ -n "${ENVIRONMENT}" ]; then
    ENVIRONMENT_NEW=$( echo $ENVIRONMENT | tr '[a-z]' '[A-Z]' )
    echo  "ENVIRONMENT: ${ENVIRONMENT_NEW:?}"
    # Environment specific keys override the defaults.
    ENV_ACCESS_KEY="ALICLOUD_ACCESS_KEY_${ENVIRONMENT_NEW}"
    export ALICLOUD_ACCESS_KEY="${!ENV_ACCESS_KEY}"
    ENV_SECRET_KEY="ALICLOUD_SECRET_KEY_${ENVIRONMENT_NEW}"
    export ALICLOUD_SECRET_KEY="${!ENV_SECRET_KEY}"
fi

# Backend config
echo bucket=\"mindsphere-ali-tfstate-${ENVIRONMENT}\" >> backend.config
#echo path=\"${CI_PROJECT_PATH}\" >> backend.config
echo region=\"${ALICLOUD_REGION}\" >> backend.config
#echo name=\"${CI_PROJECT_NAME}.tfstate\" >> backend.config
echo path=\"mindsphere-ali/platform/connectivityservices/distributedsystems/rabbitmq\" >> backend.config
echo name=\"rabbitmq.tfstate\" >> backend.config
echo encrypt=\"true\" >> backend.config

#Copy terraform tfvars from different env
echo "environment = \"${ENVIRONMENT}\"" >> terraform.tfvars || true
cat ./envs/${ENVIRONMENT}.tfvars >> terraform.tfvars || true
echo "" >> terraform.tfvars
echo "The ${ENVIRONMENT} environment terraform variables as below:"
cat terraform.tfvars || true
#Execute terraform initial job
terraform init -backend-config="backend.config"
pwd
ls
#config aliyun CLI
aliyun configure set --mode AK --language en --region ${ALICLOUD_REGION} --access-key-id ${ALICLOUD_ACCESS_KEY} --access-key-secret ${ALICLOUD_SECRET_KEY}