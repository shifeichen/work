variable "environment" {
  default = "gadev"
}
//variable "ext_domain_name" {
//  # default will be removed, default is for test
////  default = "connectivity.cn1-dev.mindsphere-in.cn"
//  default = "mdspchina1.online"
//}
variable "private_zone_prefix" {
  default = "rabbitmq"
}
variable "rabbitmq_node_count" {
  default = "2"
}

variable "acl" {
  default = "private"
}

variable "alicloud_region" {
  default = "cn-shanghai"
}

variable "alicloud_access_key" {
  default = ""
}
variable "alicloud_secret_key" {
  default = ""
}
variable "datadisk_size" {
  default = "20"
}

variable "tag_key" {
  default = "ecs_type"
}
variable "ecs_type" {
  default = "rabbitmq"
}
variable "deploy_file" {
  default = "/etc/ansible/roles/rabbitmq/deploy/deploy.yml"
}
//variable "ptr_private_zone_id" {
//  default = ""
//}

variable "user_defined_id_prefix" {
  default = "rabbitmq"
}
variable "rabbitmq_username" {}
variable "rabbitmq_password" {}
variable "rabbitmq_int_amqp_username" {}
variable "rabbitmq_int_amqp_password" {}
variable "subscriber_amqp_username" {}
variable "subscriber_amqp_password" {}
variable "host_amqp" {
  default = "amqp"
}