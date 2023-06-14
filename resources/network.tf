data "aws_availability_zones" "available" {
    state = "available"
}

data "aws_availability_zone" "available" {
    for_each = toset(data.aws_availability_zones.available.names)
    name     = each.value
}

locals {
    azs = [ for x in data.aws_availability_zone.available : x.name ]
}

resource aws_vpc network {
    cidr_block = "10.0.0.0/16"
}

resource aws_subnet public_subnet {
    vpc_id = aws_vpc.network.id
    cidr_block = "10.0.1.0/24"
    availability_zone = local.azs[0]
    map_public_ip_on_launch = true
}

resource aws_security_group allow_ssh {
    name = "Allow SSH"
    vpc_id = aws_vpc.network.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    lifecycle {

    }
}