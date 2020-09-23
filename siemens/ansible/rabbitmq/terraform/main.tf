// default settings
provider "alicloud" {
  region = "${var.alicloud_region}"
  version = "= 1.62.2"
}
provider "template" {
  version = "= 2.1.2"
}
provider "archive" {
  version = "= 1.3.0"
}
provider "local" {
  version = "= 1.4.0"
}
terraform {
  backend "oss" {}
}
data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}
data "alicloud_images" "default" {
  name_regex = "^centos_7"
  most_recent = true
  owners      = "system"
}
data "alicloud_instance_types" "default" {
  availability_zone = "${data.alicloud_zones.default.zones.0.id}"
  cpu_core_count    = 1
  memory_size       = 2
}

data "archive_file" "archive-ansible" {
  source_dir = "${path.module}/ansible/"
  output_path = "${format("%s%s","rabbitmq-${var.environment}-${timestamp()}",".zip")}"
  type = "zip"
//  depends_on = ["data.template_file.set_ansible_vars_template"]
  depends_on = ["local_file.save_ansible_vars"]
}
data "terraform_remote_state" "network" {
  backend = "oss"
  config {
    name   = "ga-network-scaffolding.tfstate"
    bucket = "mindsphere-ali-tfstate-${var.environment}"
    path   = "mindsphere-ali/ops/infrastructure/ga-network-scaffolding"
  }
}
data "terraform_remote_state" "connopcua" {
  backend = "oss"
  config {
    name    = "opcua-infrastructure.tfstate"
    bucket  = "mindsphere-ali-tfstate-${var.environment}"
    path    = "mindsphere-ali/platform/connectivityservices/infrastructures/opcua-infrastructure"
    encrypt = "true"
  }
}
/// resources
//bucket for rabbitmq
resource "alicloud_oss_bucket" "oss_bucket_ansible" {
  bucket = "rabbitmq-${var.environment}"
  acl = "${var.acl}"
}
resource "alicloud_oss_bucket_object" "oss_bucket_object" {
  bucket  = "${alicloud_oss_bucket.oss_bucket_ansible.bucket}"
  key     = "ansible"
  source = "${data.archive_file.archive-ansible.output_path}"
}
//vpc+vsw(provide by kubernetes platform latter)+sg
resource "alicloud_security_group" "default" {
  name   = "sg-rabbitmq-${var.environment}"
  vpc_id = "${data.terraform_remote_state.network.vpc_plat_id}"
}
//slb
resource "alicloud_slb_acl" "default" {
  name       = "rabbitmq-slb-acl-${var.environment}"
  ip_version = "ipv4"
  entry_list {
    entry   = "139.24.217.184/32"
    comment = "first"
  }
  entry_list {
    entry   = "139.24.217.184/32"
    comment = "second"
  }
}
#move the slb to other repo ,because it will be forever
//resource "alicloud_slb" "slb-external" {
//  name = "rabbitmq-slb-ext-${var.environment}"
//  specification = "slb.s1.small"
//  address_type = "internet"
//  instance_charge_type = "PostPaid"
//  tags = {
//    area = "connecitivity"
//    use = "rabbitmqcluster"
//    direction = "external"
//  }
//}
resource "alicloud_slb" "slb-internal" {
  name = "rabbitmq-slb-int-${var.environment}"
  specification = "slb.s1.small"
  address_type = "intranet"
  vswitch_id = "${data.terraform_remote_state.network.plat_vsw_ids[4]}"
  instance_charge_type = "PostPaid"
  tags = {
    area = "connecitivity"
    use = "rabbitmqcluster"
    direction = "internal"
  }
}
//dns
///// public zone
//resource "alicloud_dns" "external_dns" {
//  name = "externalrabbitmq.dev"
//}
/// private zone
resource "alicloud_pvtz_zone" "private_zone" {
  name = "${var.private_zone_prefix}.${var.environment}"
}
resource "alicloud_pvtz_zone_attachment" "zone-attachment" {
  zone_id = "${alicloud_pvtz_zone.private_zone.id}"
  vpc_ids = ["${data.terraform_remote_state.network.vpc_plat_id}"]
}
resource "alicloud_pvtz_zone" "ptr_private_zone" {
  name = "${format("%s.%s.in-addr.arpa","${element(split(".",data.terraform_remote_state.network.vpc_plat_cidr),1)}","${element(split(".",data.terraform_remote_state.network.vpc_plat_cidr),0)}")}"

}
resource "alicloud_pvtz_zone_attachment" "ptr_zone_attachment" {
  zone_id = "${alicloud_pvtz_zone.ptr_private_zone.id}"
  vpc_ids = ["${data.terraform_remote_state.network.vpc_plat_id}"]
}

/// public record (this will be removed ,because we have no permisson to see the ext domain ,must ask for erxing bind)
/// and output the ext slb ip to ali for binding
//resource "alicloud_dns_record" "record_ext_rabbitmq" {
//  name        = "${var.ext_domain_name}"
//  host_record = "mqtt"
//  type        = "A"
//  value       = "${alicloud_slb.slb-external.address}"
//}
/// private record
resource "alicloud_pvtz_zone_record" "record_int_rabbitmq" {
  zone_id         = "${alicloud_pvtz_zone.private_zone.id}"
  resource_record = "mqtt"
  type            = "A"
  value           = "${alicloud_slb.slb-internal.address}"
  ttl             = 60
}
resource "alicloud_pvtz_zone_record" "record_int_rabbitmq_amqp" {
  zone_id         = "${alicloud_pvtz_zone.private_zone.id}"
  resource_record = "${var.host_amqp}"
  type            = "A"
  value           = "${alicloud_slb.slb-internal.address}"
  ttl             = 60
}
//ess
resource "alicloud_ess_scaling_group" "rabbitmq" {
  min_size           = "${var.rabbitmq_node_count}"
  max_size           = "${var.rabbitmq_node_count}"
  scaling_group_name = "rabbitmq-${var.environment}"
  removal_policies   = ["OldestInstance", "NewestInstance"]
  vswitch_ids        = ["${data.terraform_remote_state.network.plat_vsw_ids[4]}"
  ,"${data.terraform_remote_state.network.plat_vsw_ids[0]}"
  ,"${data.terraform_remote_state.network.plat_vsw_ids[1]}"
  ,"${data.terraform_remote_state.network.plat_vsw_ids[2]}"
  ,"${data.terraform_remote_state.network.plat_vsw_ids[3]}"]
//  depends_on = ["alicloud_slb_listener.listener_ext_mqtt_tls","alicloud_slb_listener.listener_int_mqtt_tls","alicloud_slb_listener.listener_int_amqp","alicloud_slb_listener.listener_int_http"]
  depends_on = ["alicloud_slb_listener.listener_ext_mqtt_tls","alicloud_slb_listener.listener_int_mqtt_tls","alicloud_slb_listener.listener_int_amqp"]
  loadbalancer_ids = ["${data.terraform_remote_state.connopcua.rabbitmq_slb_external_id}","${alicloud_slb.slb-internal.id}"]
}
data "template_file" "cloud-init" {
  template = "${file("${path.module}/cloud-init.yaml")}"
  vars {
    region            = "${var.alicloud_region}"
    environment       = "${var.environment}"
    scaling_group_name   =  "${alicloud_ess_scaling_group.rabbitmq.scaling_group_name}"
    alicloud_access_key    = "${var.alicloud_access_key}"
    alicloud_secret_key    = "${var.alicloud_secret_key}"
    bucket_name       = "${alicloud_oss_bucket.oss_bucket_ansible.bucket}"
    role_name         = "${alicloud_ram_role.role.name}"
    private_zone = "${alicloud_pvtz_zone.private_zone.name}"
    slb_mqttauthrouter_address = "${data.terraform_remote_state.connopcua.slb_mqttauthrouter_address}"
  }
}
resource "alicloud_key_pair" "pair" {
  key_name = "rabbitmq-${var.environment}"
  key_file = "${file("${path.module}/key/private.key")}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtA7kd52aUeSZn0INv/+jrGHdWMPc9lE39qbAO/RAtPGcTS7ry3uboq9QuFy3wyCeomaVyIjfS9HCzK6UZAOXFuo5vJl9yKmnz9nmQuqu8WPk7SW0cNXQzEEAAxNR4/58Fai7CrdIgAOrtPzKyshliM1abvGEnF+Foqh4fEPEAN/wjrUYXEjrIVfdx/xhOCW1GDJXAiBzqlzrhLlzwGURNqGFc8bQe4kt2LEeL20D1RLo948JKTjb0tvOfJqgfjzrRZB0H300fyOG/qES24Z5G7XBuWHCY5nRiLrRf2KOF7mUS0LDVyN2n+Y+eD3GTKcN5vkCTUdsBg395Cd+8L+jb cluster@ansible"
}

resource "alicloud_ess_scaling_configuration" "default" {
  scaling_configuration_name = "rabbitmq-scaling-configuration-${var.environment}"
  scaling_group_id  = "${alicloud_ess_scaling_group.rabbitmq.id}"
//  image_id          = "${data.alicloud_images.default.images.0.id}"
  image_id = "centos_7_7_64_20G_alibase_20191008.vhd"
  instance_type     = "${data.alicloud_instance_types.default.instance_types.0.id}"
  security_group_id = "${alicloud_security_group.default.id}"
  system_disk_size = "40"
  system_disk_category = "cloud_efficiency"
  force_delete      = true
  enable = "true"
  active = "true"
  data_disk {
    size = "${var.datadisk_size}"
    category = "cloud_efficiency"
    delete_with_instance = "true"
  }
  tags {
    ecs_type = "${var.ecs_type}"
  }
  user_data = "${data.template_file.cloud-init.rendered}"
  key_name = "${alicloud_key_pair.pair.key_name}"
  role_name = "${alicloud_ram_role.role.name}"
}

