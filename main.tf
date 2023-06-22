module "resources" {
    source    = "./resources"
    instance_type = var.instance_type
    slack_webhook_url = var.slack_webhook_url
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
