#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_REGION>"
  exit 1
fi

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

export AWS_ACCESS_KEY_ID="$1"
export AWS_SECRET_ACCESS_KEY="$2"
export AWS_REGION="$3"

cat > backend-config.hcl <<EOL
bucket = "eks-test-mastercard"
key    = "terraform.tfstate"
region = "$AWS_REGION"
EOL

echo "Access Key ID: $AWS_ACCESS_KEY_ID"
echo "Secret Access Key: $AWS_SECRET_ACCESS_KEY"

terraform init -backend-config=backend-config.hcl -migrate-state
terraform plan
terraform apply -auto-approve

