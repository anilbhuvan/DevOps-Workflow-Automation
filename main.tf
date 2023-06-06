terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.0"
      }
    }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "project-1" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "project-1-vpc"
  }
}

# create a subnet
resource "aws_subnet" "project-1-public-1a" {
  vpc_id            = aws_vpc.project-1.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.0.0/17"
  tags = {
    Name = "project-1-public-subnet-1a"
  }
}

resource "aws_subnet" "project-1-public-1b" {
  vpc_id            = aws_vpc.project-1.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.128.0/18"
  tags = {
    Name = "project-1-public-subnet-1b"
  }
}

resource "aws_subnet" "project-1-public-1c" {
  vpc_id            = aws_vpc.project-1.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.192.0/18"
  tags = {
    Name = "project-1-public-subnet-1c"
  }
}

# Create a Internet_Gateway
resource "aws_internet_gateway" "project-1-gw" {
  vpc_id = aws_vpc.project-1.id

  tags = {
    Name = "project-1-gw"
  }
}

# Create a Route_table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.project-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project-1-gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.project-1-gw.id
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "subnet-1-association" {
  subnet_id      = aws_subnet.project-1-public-1a.id
  route_table_id = aws_route_table.rt.id
}

# Associate subnet with route table
resource "aws_route_table_association" "subnet-2-association" {
  subnet_id      = aws_subnet.project-1-public-1b.id
  route_table_id = aws_route_table.rt.id
}

# Associate subnet with route table
resource "aws_route_table_association" "subnet-3-association" {
  subnet_id      = aws_subnet.project-1-public-1c.id
  route_table_id = aws_route_table.rt.id
}

# create a Security Group
resource "aws_security_group" "Project_SG" {
  name        = "project_SG"
  description = "Allow HTTP HTTPS ICMP ssh"
  vpc_id      = aws_vpc.project-1.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

    ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

    ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

    ingress {
    description      = "ICMP"
    from_port        = 0
    to_port          = 0
    protocol         = "ICMP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

    ingress {
    description      = "port 2368"
    from_port        = 2368
    to_port          = 2368
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

    ingress {
    description      = "port 3001"
    from_port        = 3001
    to_port          = 3001
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Project_SG"
  }
}

# create aws key pair
resource "aws_key_pair" "project-key" {
  key_name   = "project-key"
  public_key = tls_private_key.rsa-4096-example.public_key_openssh
}

# create a private key in aws
resource "tls_private_key" "rsa-4096-example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# save pem file to local host
resource "local_file" "private-key" {
  content  = tls_private_key.rsa-4096-example.private_key_pem
  filename = "project-key.pem"
}

# creat a instance
resource "aws_instance" "Instance-1" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "t2.medium"
  availability_zone           = "us-east-1a"
  key_name                    = "project-key"
  security_groups             = [aws_security_group.Project_SG.id]
  subnet_id                   = aws_subnet.project-1-public-1a.id
  associate_public_ip_address = true
  user_data                   = file("./AWS_Ubuntu_Script.sh")
  depends_on = [
    aws_key_pair.project-key
  ]

  tags = {
    "Name" = "Instance-1"
  }
}