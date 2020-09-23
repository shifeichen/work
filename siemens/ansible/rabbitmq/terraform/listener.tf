/// will change the port and use the certificates
//resource "alicloud_slb_listener" "listener_ext_mqtt" {
//  load_balancer_id          = "${alicloud_slb.slb-external.id}"
//  backend_port = "1883"
//  frontend_port = "1883"
//  protocol = "tcp"
//  bandwidth = "1"
//  health_check_type = "tcp"
//}
resource "alicloud_slb_listener" "listener_ext_mqtt_tls" {
  load_balancer_id          = "${data.terraform_remote_state.connopcua.rabbitmq_slb_external_id}"
  backend_port = "8883"
  frontend_port = "8883"
  protocol = "tcp"
  bandwidth = "1"
  health_check_type = "tcp"
  health_check_interval = "50"
}
/// will change the port and use the certificates,use https replaced
//resource "alicloud_slb_listener" "listener_ext_http" {
//  load_balancer_id          = "${data.terraform_remote_state.connopcua.rabbitmq_slb_external_id}"
//  backend_port = "15672"
//  frontend_port = "80"
//  protocol = "tcp"
//  bandwidth = "1"
//  health_check_type = "tcp"
//  //  acl_id = "${alicloud_slb_acl.default.id}" #only for local to access
//}
/// test for amqp port
//resource "alicloud_slb_listener" "listener_ext_amqp" {
//  load_balancer_id          = "${data.terraform_remote_state.connopcua.rabbitmq_slb_external_id}"
//  backend_port = "5672"
//  frontend_port = "5672"
//  protocol = "tcp"
//  bandwidth = "1"
//  health_check_type = "tcp"
//  health_check_interval = "50"
//  //  acl_id = "${alicloud_slb_acl.default.id}" #only for local to access
//}
resource "alicloud_slb_listener" "listener_ext_https" {
  load_balancer_id          = "${data.terraform_remote_state.connopcua.rabbitmq_slb_external_id}"
  backend_port = "15671"
  frontend_port = "443"
//  frontend_port = "15671"
  protocol = "tcp"
  bandwidth = "1"
  health_check_type = "tcp"
  health_check_interval = "50"
  //  acl_id = "${alicloud_slb_acl.default.id}" #only for local to access
}
resource "alicloud_slb_listener" "listener_ext_ssh" {
  load_balancer_id          = "${data.terraform_remote_state.connopcua.rabbitmq_slb_external_id}"
  backend_port = "22"
  frontend_port = "22"
  protocol = "tcp"
  bandwidth = "1"
  health_check_type = "tcp"
  health_check_interval = "50"
  //  acl_id = "${alicloud_slb_acl.default.id}" #only for local to access
}

///// will use certificates and change the port to 8883
//resource "alicloud_slb_listener" "listener_int_mqtt" {
//  load_balancer_id          = "${alicloud_slb.slb-internal.id}"
//  backend_port = "1883"
//  frontend_port = "1883"
//  protocol = "tcp"
//  health_check_type = "tcp"
//  bandwidth = "10"
//}
resource "alicloud_slb_listener" "listener_int_mqtt_tls" {
  load_balancer_id          = "${alicloud_slb.slb-internal.id}"
  backend_port = "8883"
  frontend_port = "8883"
  protocol = "tcp"
  health_check_type = "tcp"
  bandwidth = "10"
  health_check_interval = "50"
}
# internal expose http too
resource "alicloud_slb_listener" "listener_int_http" {
  load_balancer_id          = "${alicloud_slb.slb-internal.id}"
  backend_port = "15672"
  frontend_port = "15672"
  protocol = "tcp"
  health_check_type = "tcp"
  bandwidth = "10"
  health_check_interval = "50"
}
resource "alicloud_slb_listener" "listener_int_https" {
  load_balancer_id          = "${alicloud_slb.slb-internal.id}"
  backend_port = "15671"
  frontend_port = "15671"
  protocol = "tcp"
  health_check_type = "tcp"
  bandwidth = "10"
  health_check_interval = "50"
}
resource "alicloud_slb_listener" "listener_int_amqp" {
  load_balancer_id          = "${alicloud_slb.slb-internal.id}"
  backend_port = "5672"
  frontend_port = "5672"
  protocol = "tcp"
  health_check_type = "tcp"
  bandwidth = "10"
  health_check_interval = "50"
}