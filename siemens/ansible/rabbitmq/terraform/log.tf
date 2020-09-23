resource "alicloud_log_project" "log_project" {
  name        = "rabbitmq-${var.environment}"
}
resource "alicloud_log_store" "log_store" {
  project               = "${alicloud_log_project.log_project.name}"
  name                  = "rabbitmq-${var.environment}"
  retention_period      = 7
}
resource "alicloud_log_machine_group" "log_machine_group" {
  project       = "${alicloud_log_project.log_project.name}"
  name          = "rabbitmq-lmg-${var.environment}"
  identify_type = "userdefined"
  identify_list = ["${var.user_defined_id_prefix}-${var.environment}"]
}
resource "alicloud_logtail_config" "logtail_config" {
  project      = "${alicloud_log_project.log_project.name}"
  logstore     = "${alicloud_log_store.log_store.name}"
  input_type   = "file"
  name         = "rabbitmq-lc-${var.environment}"
  output_type  = "LogService"
  input_detail = <<DEFINITION
    {
        "logPath": "/var/log/rabbitmq",
        "filePattern": "rabbit@*.log",
        "logType": "json_log",
        "topicFormat": "default",
        "discardUnmatch": false,
        "enableRawLog": true,
        "fileEncoding": "gbk",
        "maxDepth": 10
    }
    DEFINITION
}
resource "alicloud_logtail_attachment" "test" {
  project = "${alicloud_log_project.log_project.name}"
  logtail_config_name = "${alicloud_logtail_config.logtail_config.name}"
  machine_group_name = "${alicloud_log_machine_group.log_machine_group.name}"
}
resource "alicloud_log_store_index" "log_store_index" {
  project = "${alicloud_log_project.log_project.name}"
  logstore = "${alicloud_log_store.log_store.name}"
  full_text {
    case_sensitive = true
    token = ", '\";=()[]{}?@&<>/:\n\t\r"
  }
}