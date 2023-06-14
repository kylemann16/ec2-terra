module "resources" {
    source    = "./resources"
    instance_type = var.instance_type
}

variable instance_type {
    type = string
    default = "g4dn.4xlarge"
}