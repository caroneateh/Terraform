terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.53.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "BOA" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "BOA"
  }
}

resource "aws_subnet" "BOA-private" {
  vpc_id     = aws_vpc.BOA.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name = "BOA-private"
  }
}

resource "aws_internet_gateway" "BOA-igw" {
  vpc_id = aws_vpc.BOA.id
  tags = {
    Name = "BOA-igw"
  }
}

resource "aws_route_table" "BOA-route" {
  vpc_id = aws_vpc.BOA.id
  route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.BOA-igw.id
  }

  tags = {
    Name = "BOA-route"
  }
}

resource "aws_main_route_table_association" "route-subnet" {
  vpc_id         = aws_vpc.BOA.id
  route_table_id = aws_route_table.BOA-route.id
}

resource "aws_security_group" "BOA-SG" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.BOA.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "for https"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "BOA-SG"
  }
}

  resource "aws_instance" "BOA-server" {
  ami           = "ami-0aa7d40eeae50c9a9"
  instance_type = var.instance_type
  key_name = "Terraform"
  subnet_id = aws_subnet.BOA-private.id
  vpc_security_group_ids = [aws_security_group.BOA-SG.id]
  availability_zone = var.availability_zone
  associate_public_ip_address = true
  user_data = file("entry-script.sh")
  tags = {
    Name = "BOA-server"
  }
}

resource "aws_instance" "BOA-app" {
  ami = "ami-0aa7d40eeae50c9a9"
  instance_type = var.instance_type
  key_name = "Terraform"
  subnet_id = aws_subnet.BOA-private.id
  vpc_security_group_ids = [aws_security_group.BOA-SG.id]
  availability_zone = var.availability_zone
  associate_public_ip_address = true
  user_data = file("entry-script.sh")
  tags = {
    Name = "BOA-app"
  }
}

resource "aws_instance" "Chase-app" {
  ami = "ami-0aa7d40eeae50c9a9"
  instance_type = var.instance_type
  key_name = var.public_key
  subnet_id = aws_subnet.BOA-private.id
  vpc_security_group_ids = [aws_security_group.BOA-SG.id]
  availability_zone = var.availability_zone
  associate_public_ip_address = true
  tags = {
    Name = "Chase-app"
  }
}

resource "aws_key_pair" "BOA-key" {
  key_name   = "BOA-key"
  public_key = var.public_key
}

variable "vpc_cidr_block" {
    description = "vpc cidr block"
}

variable "subnet_cidr_block" {
    description = "subnet cidr block"
  }

variable "instance_type" {
    description = "instance type"
  }
    

variable "availability_zone" {
    description = "availability zone"
  }

variable "public_key" {
    description = "public_key"
  }

output "ec2_public_ip" {
    value = aws_instance.BOA-app.public_ip
  }



  


  


