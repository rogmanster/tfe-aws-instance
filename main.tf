terraform {
  required_version = ">= 0.11.0"
}

data "terraform_remote_state" "aws_vpc_prod" {
  backend = "remote"

  config = {
    organization = "rogercorp"
    workspaces = {
      name = "aws-vpc-prod"
    }
  }
}

data "terraform_remote_state" "aws_security_group" {
  backend = "remote"

  config = {
    organization = "rogercorp"
    workspaces = {
      name = "aws-security-group-prod"
    }
  }
}

data "aws_key_pair" "example" {
  key_name           = "rchao-key"
  include_public_key = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

provider "aws" {
}

resource "random_id" "name" {
  byte_length = 4
}

resource "aws_instance" "ubuntu" {
  count                   = var.instance_count
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  key_name                = data.aws_key_pair.example.key_name
  vpc_security_group_ids  = [data.terraform_remote_state.aws_security_group.outputs.security_group_id]
  subnet_id               = data.terraform_remote_state.aws_vpc_prod.outputs.public_subnets[0]

  tags = {
    name        = var.name
    ttl         = var.ttl
    env         = var.env
    Description = "This branch updated v1.0.3"
  }

  //requires Terraform v1.2 or higher
  //https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#self-object
  lifecycle {
    postcondition {
      condition     = self.instance_state == "running"
      error_message = "EC2 instance must be running."
    }
  }
}
