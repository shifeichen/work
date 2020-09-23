//ram role for ecs to access oss
# Create a new RAM Role.
resource "alicloud_ram_role" "role" {
  name     = "rabbitmq-${var.environment}"
  document = <<EOF
  {
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "ecs.aliyuncs.com"
          ]
        }
      }
    ],
    "Version": "1"
  }
  EOF
  description = "this is a role for rabbitmq"
  force = true
}
resource "alicloud_ram_policy" "policy" {
  name     = "rabbitmq-${var.environment}"
  document = <<EOF
  {
    "Statement": [
      {
        "Action": [
          "oss:List*",
          "oss:Get*",
          "pvtz:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ],
      "Version": "1"
  }
  EOF
  description = "this is a policy for rabbitmq"
  force = true
}
resource "alicloud_ram_role_policy_attachment" "attach" {
  policy_name = "${alicloud_ram_policy.policy.name}"
  policy_type = "${alicloud_ram_policy.policy.type}"
  role_name   = "${alicloud_ram_role.role.name}"
}