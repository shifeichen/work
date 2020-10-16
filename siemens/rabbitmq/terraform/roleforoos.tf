# Create a new RAM Role for oos to access ecs to run command.
resource "alicloud_ram_role" "ecsruncmd" {
  name     = "ecsruncmd-${var.environment}"
  document = <<EOF
  {
      "Statement": [
          {
              "Action": "sts:AssumeRole",
              "Effect": "Allow",
              "Principal": {
                  "Service": [
                      "oos.aliyuncs.com"
                  ]
              }
          }
      ],
      "Version": "1"
  }
  EOF
  description = "oos access ecs"
  force = true
}
resource "alicloud_ram_policy" "ecsruncmdpolicy" {
  name     = "ecsruncmd-${var.environment}"
  document = <<EOF
  {
      "Version": "1",
      "Statement": [
          {
              "Action": [
                  "ecs:RunCommand",
                  "ecs:Describe*",
                  "vpc:Describe*"
              ],
              "Resource": "*",
              "Effect": "Allow"
          }
      ]
  }
  EOF
  description = "ecs run command"
  force = true
}
resource "alicloud_ram_role_policy_attachment" "ecsruncmdattach" {
  policy_name = "${alicloud_ram_policy.ecsruncmdpolicy.name}"
  policy_type = "${alicloud_ram_policy.ecsruncmdpolicy.type}"
  role_name   = "${alicloud_ram_role.ecsruncmd.name}"
}
