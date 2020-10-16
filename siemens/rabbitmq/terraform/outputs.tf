/// outputs
output "slb_ext_id" {
  value = "${data.terraform_remote_state.connopcua.rabbitmq_slb_external_id}"
}

output "slb_ext_address" {
  value = "${data.terraform_remote_state.connopcua.rabbitmq_slb_external_address}"
}
output "slb_int_id" {
  value = "${alicloud_slb.slb-internal.id}"
}
output "slb_int_address" {
  value = "${alicloud_slb.slb-internal.address}"
}

output "int_domain_name" {
  value = "${alicloud_pvtz_zone.private_zone.name}"
}
output "image_name" {
  value = "${data.alicloud_images.default.images.0.id}"
}
output "role_name" {
  value = "${alicloud_ram_role.role.name}"
}
output "oos_role" {
  value = "${alicloud_ram_role.ecsruncmd.name}"
}
output "slb_mqttauthrouter_address" {
  value = "${data.terraform_remote_state.connopcua.slb_mqttauthrouter_address}"
}

output "private_zone" {
  value = "${alicloud_pvtz_zone.private_zone.name}"
}
//output "ptr_private_zone" {
//  value = "${alicloud_pvtz_zone.ptr_private_zone.name}"
//}
output "private_zone_id" {
  value = "${alicloud_pvtz_zone.private_zone.id}"
}
#current output the stable,latter replace by refer and not run in gadev
output "ptr_private_zone_id" {
//    value = "${var.ptr_private_zone_id}"
  value = "${alicloud_pvtz_zone.ptr_private_zone.id}"
}
output "region" {
  value = "${var.alicloud_region}"
}
output "tag_value" {
  value = "${alicloud_ess_scaling_configuration.default.tags.ecs_type}"
}
output "oss_bucket" {
  value = "${alicloud_oss_bucket.oss_bucket_ansible.bucket}"
}
output "object_key" {
  value = "${alicloud_oss_bucket_object.oss_bucket_object.key}"
}
output "amqp_full_int_domain_name" {
  value = "${var.host_amqp}.${alicloud_pvtz_zone.private_zone.name}"
}