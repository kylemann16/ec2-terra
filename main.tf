module "resources" {
    source    = "./resources"
    instance_type = var.instance_type
    slack_webhook_url = var.slack_webhook_url
    aws_region = var.aws_region
}

variable aws_region {
    type = string
    default = "us-west-2"
}

variable instance_type {
    type = string
    default = "g4dn.4xlarge"
}

variable slack_webhook_url {
    type = string
}

output ip_address {
    value = module.resources.ip_address
}
