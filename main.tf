provider "aws" {
    region= "eu-west-3"
}
variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable env_prefix {} 
variable avail_zone {}
variable my_ip { }
variable instance_type { }

resource "aws_vpc" "myaapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
 
    }
}
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myaapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}
resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myaapp-vpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myapp-igw.id
    } 
    tags = {
      "Name" = "${var.env_prefix}-rtb"
    }
    
}
resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myaapp-vpc.id 
    tags = {
      "Name" = "${var.env_prefix}-igw"
    }
}
  
resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
  
}  

resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myaapp-vpc.id

    ingress  {
      cidr_blocks = [var.my_ip]
      description = "allow ssh from my ip"
      from_port = 22 
      protocol = "tcp"
      to_port = 22
    } 

    ingress {
      cidr_blocks = ["0.0.0.0/0"]
      description = "allow http from internet"
      from_port = 8080 
      protocol = "tcp"
      to_port = 8080
    } 
    
    egress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 0 
      protocol = "-1"
      to_port = 0
    } 
   
   tags = {
      "Name" = "${var.env_prefix}-sg"
    }


}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true 
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}
#utput "amzon_ami_id" {
#   value = data.aws_ami.latest-amazon-linux-image.id
# 
#}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id] 
    associate_public_ip_address = true 
    key_name = "terraform"

    user_data = <<EOF
                    #!/bin/bash
                    sudo yum update - && sudo yum install -y docker
                    sudo systemctl start docker
                    sudo usermod -aG docker ec2-user
                    docker run -p 8080:80 nginx
                EOF
    tags = {
      "Name" = "${var.env_prefix}-server"
    }
}