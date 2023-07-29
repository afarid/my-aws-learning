provider "aws" {
  region = "eu-west-1"
}
// VPC resources
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "demo-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24"]

  enable_nat_gateway = true


  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

// Creates a s3 endpoint to allow access to s3 from within the VPC
resource "aws_vpc_endpoint" "s3" {
  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-west-1.s3"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.private-sg.id]
  subnet_ids          = module.vpc.private_subnets
}
// Creates a ssm endpoint to allow access to ssm from within the VPC
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.eu-west-1.ssm"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.private-sg.id]
  subnet_ids          = module.vpc.private_subnets
}

// Get image id for ubuntu 20.04
data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

// Creates an instance with the image id from above
resource "aws_instance" "this" {
  ami                    = data.aws_ami.this.id
  subnet_id              = module.vpc.private_subnets[0]
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.this.name
  vpc_security_group_ids = [aws_security_group.private-sg.id]
  tags                   = {
    Name = "s3-client"
  }
}

resource "aws_security_group" "private-sg" {
  name        = "private-sg"
  description = "Allow all outbound traffic and inbound traffic from VPC"

  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Allow all inbound traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "this" {
  name = "s3-client-instance-profile"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name = "s3-client-instance-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}


## provides access to SSM
resource "aws_iam_policy_attachment" "ssm_access" {
  name       = "ssm-access"
  roles      = [aws_iam_role.this.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

## provides access to S3
resource "aws_iam_policy_attachment" "s3_access" {
  name       = "ss3-access"
  roles      = [ aws_iam_role.this.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}