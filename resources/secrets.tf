resource aws_key_pair ec2_key_pair {
    key_name_prefix = "ec2_terra_"
    public_key = tls_private_key.rsa_key.public_key_openssh
}

resource tls_private_key rsa_key {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource local_file ssh_pem {
    content = tls_private_key.rsa_key.private_key_pem
    filename = "${path.module}/../.secrets/ssh.pem"
    file_permission = "400"
}
