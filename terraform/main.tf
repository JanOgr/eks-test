terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.82.2"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-eks-test"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-test-internet-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "route-table-eks-test"
  }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  route_table_id = aws_route_table.public.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public_subnet.*.id

  cluster_name    = "eks-test"
  cluster_version = "1.31"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    example = {
      instance_types = ["t3.medium"]
      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}

resource "aws_iam_role" "fluentd_role" {
  name = "fluentd-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.eu-north-1.amazonaws.com/id/070D69D145531666DE47C284189717A0"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.eks.eu-north-1.amazonaws.com/id/070D69D145531666DE47C284189717A0:sub" = "system:serviceaccount:kube-system:fluentd"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "fluentd_policy" {
  name        = "fluentd-cloudwatch-policy"
  description = "Policy for Fluentd to write logs to CloudWatch and list resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
      "Resource" = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeRegions"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "kubernetes:pods",
          "kubernetes:pods/list",
          "kubernetes:pods/watch",
          "kubernetes:namespaces",
          "kubernetes:namespaces/list",
          "kubernetes:namespaces/watch"
        ]
        Resource = "*"
      },
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fluentd_policy_attachment" {
  role       = aws_iam_role.fluentd_role.name
  policy_arn = aws_iam_policy.fluentd_policy.arn
}
