#!/usr/bin/env sh

cd "$(dirname "$0")"

conda env create -f env.yml
conda activate ec2-terra