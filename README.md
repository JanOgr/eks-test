# eks-test
Test deployment of a sample RabbitMQ application on an Amazon EKS cluster. 
It includes Terraform scripts for provisioning the EKS cluster, a yaml file for deploying RabbitMQ,
and a GitHub Actions workflow for automating the deployment process. 

## Prerequisites

- Install the following tools (MacOs):
```shell
    brew install terraform
    brew install awscli
    brew install kubernetes-cli
```
- Set up you aws configuration `aws configure --profile <profile_name>` or export the following environment variables
```shell
    export AWS_ACCESS_KEY_ID="<key_id>"
    export AWS_SECRET_ACCESS_KEY="<secret_key>"
    export AWS_SESSION_TOKEN="<session_token>"
```

## Deploy the eks cluster
 Navigate to the `terraform` folder and run the following commands
```shell
    terraform init
    terraform plan
    terraform apply
```
aws eks --region <region> update-kubeconfig --name eks-test


## Destroy the eks cluster
 Navigate to the `terraform` folder and run the following commands
```shell
    terraform destroy
```

## Run deployment script
Navigate to the `terraform` folder and run the following command (assuming the env vars are defined).
```shell
    ./deploy.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY $AWS_REGION
```

## Deploy rabbitmq

```shell
  kubectl apply -f rabbitmq.yaml
```