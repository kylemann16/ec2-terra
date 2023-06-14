#!/usr/bin/env sh

cd "$(dirname "$0")"

conda env create -f env.yml
conda activate ec2-terra

mkdir -p .secrets
FILE_PATH=".secrets/ssh.pem"

echo -e $(aws secretsmanager get-secret-value \
    --secret-id keypairs/intern_data_processing \
    --query SecretString | tr -d '"') > $FILE_PATH

chmod 400 $FILE_PATH