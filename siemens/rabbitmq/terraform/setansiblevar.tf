data "template_file" "set_ansible_vars_template" {
  template = "${file("${path.module}/ansible/rabbitmq/vars/main.yml")}"
  vars {
    private_zone_id = "${alicloud_pvtz_zone.private_zone.id}"
//    ptr_private_zone_id = "${var.ptr_private_zone_id}"
    ptr_private_zone_id = "${alicloud_pvtz_zone.ptr_private_zone.id}"
    ram_role_name = "${alicloud_ram_role.role.name}"
    private_zone = "${alicloud_pvtz_zone.private_zone.name}"
    slb_mqttauthrouter_address = "${data.terraform_remote_state.connopcua.slb_mqttauthrouter_address}"
    deploy_environment = "${var.environment}"
    user_defined_id = "${var.user_defined_id_prefix}-${var.environment}"
    rabbitmq_username = "${var.rabbitmq_username}"
    rabbitmq_password = "${var.rabbitmq_password}"
    rabbitmq_int_amqp_username = "${var.rabbitmq_int_amqp_username}"
    rabbitmq_int_amqp_password = "${var.rabbitmq_int_amqp_password}"
    sub_amqp_username = "${var.subscriber_amqp_username}"
    sub_amqp_password = "${var.subscriber_amqp_password}"
  }
}

resource "local_file" "save_ansible_vars" {
  content  = "${data.template_file.set_ansible_vars_template.rendered}"
  filename = "./ansible/rabbitmq/vars/main.yml"
}