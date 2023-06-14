### STARTUP

```
source env.sh
terraform init
terraform apply
```

This set of commands will:
1. Create an environment named ec2-terra, which contains terraform and aws-cli. This script will also pull the keypair from the secrets manager so you can access the ec2 instance via ssh.
2. Initialize Terraform resoruces
3. Apply terraform changes, which will create an ec2 instance that will be started and stopped at 8am and 5pm, respectively, every week day.
4. When the apply is down, the public ip of the created ec2 instance will be printed to the command line.

To then connect to the generated ec2 instance run:

```
ssh -i .secrets/ssh.pem ec2-user@${instance_ip}
```