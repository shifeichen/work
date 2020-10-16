#!/usr/bin/env bash

ENV_VAR=(
    subscriber_amqp_username
    subscriber_amqp_password
    rabbitmq_int_amqp_username
    rabbitmq_int_amqp_password
    rabbitmq_username
    rabbitmq_password
    )
ALLOW_ENVIRONMENT=(
    gainteg
    gaprod
    )

function export_vars (){
    for env_var in ${ENV_VAR[*]};do
        echo "Getting the ${env_var} from gitlab setting variable<${env_var}_$ENVIRONMENT> for $ENVIRONMENT..."
        env_tmp_var=${env_var}_$ENVIRONMENT
        if [ -n "${!env_tmp_var}" ];then
            export ${env_var}=${!env_tmp_var}
        else
            echo "get ${env_var} failed from gitlab setting variable<$env_tmp_var> for $ENVIRONMENT"
            exit 2
        fi
    done
    if [[ ${CI_CD_MODE} = "test" ]];then
        for env_var in ${ENV_VAR[*]};do
            echo "${env_var}: ${!env_var}"
        done
    fi
}
function set_vars_to_terraform() {
    for env_var in ${ENV_VAR[*]};do
        echo "Getting the ${env_var} from gitlab setting variable<${env_var}_$ENVIRONMENT> for $ENVIRONMENT..."
        env_tmp_var=${env_var}_$ENVIRONMENT
        if [ -n "${!env_tmp_var}" ];then
            echo "${env_var} = \"${!env_tmp_var}\"" >> terraform.tfvars;
        else
            echo "get ${env_var} failed from gitlab setting variable<$env_tmp_var> for $ENVIRONMENT"
            exit 2
        fi
    done
    if [[ ${CI_CD_MODE} = "test" ]];then
        for env_var in ${ENV_VAR[*]};do
            echo "${env_var}: ${!env_var}"
        done
    fi
}
case $1 in
  set_vars_to_terraform)
    set_vars_to_terraform
  ;;
  export_vars)
    export_vars
  ;;
  *)
    echo "please give a parameter"
    exit 2
  ;;
esac

