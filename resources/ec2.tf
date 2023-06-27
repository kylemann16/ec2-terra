resource random_string run_id {
    length = 5
    special = false
}

variable instance_type {
    type = string
    default = "g4dn.4xlarge"
}

data aws_ami al2 {
    most_recent = true

    filter {
        name   = "owner-alias"
        values = ["amazon"]
    }

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm*"]
    }
}

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended"
}


resource aws_instance instance {
    instance_type = var.instance_type
    tags = {
        Name = "Intern_Data_Processor_${random_string.run_id.result}"
    }
    user_data = filebase64("${path.module}/userdata.sh")
    subnet_id = aws_subnet.public_subnets[1].id
    ami = jsondecode(data.aws_ssm_parameter.ami.value).image_id
    key_name = aws_key_pair.ec2_key_pair.key_name
    security_groups = [ aws_security_group.allow_ssh.id ]
    # instance_market_options {
    #     market_type = "spot"
    # }
}

resource aws_scheduler_schedule starter {
    name = "EC2_Cron_starter_${random_string.run_id.result}"
    group_name = "default"
    flexible_time_window {
        mode = "OFF"
    }

    schedule_expression_timezone = "America/Chicago"
    schedule_expression = "cron(0 8 ? * MON-FRI *)"

    target {
        arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
        role_arn = aws_iam_role.start_stop_ec2.arn
        input = jsonencode({
            InstanceIds = [
                aws_instance.instance.id
            ]
        })
    }
}

resource aws_scheduler_schedule stopper {
    name = "EC2_Cron_stopper_${random_string.run_id.result}"
    group_name = "default"
    flexible_time_window {
        mode = "OFF"
    }
    schedule_expression_timezone = "America/Chicago"
    schedule_expression = "cron(0 17 ? * MON-FRI *)"

    target {
        arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
        role_arn = aws_iam_role.start_stop_ec2.arn
        input = jsonencode({
            InstanceIds = [
                aws_instance.instance.id
            ]
        })
    }
}

resource aws_iam_policy iam_policy {
    name = "EC2_Start_Stop_IAM_Policy_${random_string.run_id.result}"
    policy = jsonencode({
            Version = "2012-10-17"
            Statement = [{
                Effect = "Allow"
                Action = [
                    "ec2:StopInstances",
                    "ec2:StartInstances",
                    "ec2:DescribeInstanceStatus",
                    "ec2:DescribeInstances",
                ]
                Resource = ["*"]
            }]
    })
}

resource aws_iam_role start_stop_ec2 {
    name = "EC2_Start_and_Stop_${random_string.run_id.result}"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = ["scheduler.amazonaws.com"]
            }
            Action = "sts:AssumeRole"
        }]
    })
}

resource aws_iam_role_policy_attachment role_attach {
    role = aws_iam_role.start_stop_ec2.name
    policy_arn = aws_iam_policy.iam_policy.arn
}

output ip_address {
    value = aws_instance.instance.public_ip
}