module "resources" {
    source    = "./resources"
    instance_type = var.instance_type
}

variable instance_type {
    type = string
    default = "g4dn.4xlarge"
}

variable emails {
    type = list(string)
}

output ip_address {
    value = module.resources.ip_address
}
