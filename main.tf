terraform {
  required_version = ">= 0.11.0"
}

// Workspace Data
data "terraform_remote_state" "aws_vpc_prod" {
  backend = "remote"

  config = {
    organization = "rogercorp"
    workspaces = {
      name = "aws-vpc-prod"
    }
  }
}

// Workspace Data
data "terraform_remote_state" "aws_security_group" {
  backend = "remote"

  config = {
    organization = "rogercorp"
    workspaces = {
      name = "aws-security-group-prod"
    }
  }
}

data "aws_ami" "rhel_ami" {
  most_recent = true
  owners      = ["309956199498"]

  filter {
    name   = "name"
    values = ["*RHEL-7.3_HVM_GA-*"]
  }
}

provider "aws" {
}

resource "random_id" "name" {
  byte_length = 4
}

resource "aws_key_pair" "awskey" {
  key_name   = "awskwy-${random_id.name.hex}"
  public_key = tls_private_key.awskey.public_key_openssh
}

resource "aws_instance" "ubuntu" {
  count                   = var.instance_count
  ami                     = data.aws_ami.rhel_ami.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.awskey.key_name
  vpc_security_group_ids  = [data.terraform_remote_state.aws_security_group.outputs.security_group_id]
  subnet_id               = data.terraform_remote_state.aws_vpc_prod.outputs.public_subnets[0]

  tags = {
    Name        = var.name
    TTL         = var.ttl
    Owner       = var.owner
    Description = "This branch updated v6"
  }
}
