provider "aws" {
    region= "eu-west-3"
}

variable "cidr_blocks" {
    description = "subnet and vpc cidr blocks"
    type = list(object ({
        cidr_block = string
        name = string
 
    }))
}

variable "environment" {
    description = "deployment environment"

} 

variable avail_zone {}

resource "aws_vpc" "development-vpc" {
    cidr_block = var.cidr_blocks[0].cidr_block
    tags = {
        Name: var.cidr_blocks[0].name
        pvc_env: "dev"
    }
}
resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.development-vpc.id
    cidr_block = var.cidr_blocks[1].cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "subnet-1-dev"
    }
}
data "aws_vpc" "existing_vpc"{
    default = true
}

resource "aws_subnet" "dev-subnet-2" {
    vpc_id = data.aws_vpc.existing_vpc.id
    cidr_block = "172.31.20.0/24"
    availability_zone = var.avail_zone
    tags = {
        Name: "subnet-2-dev"
    }
    
}

output "vpc_id" {
    value = aws_vpc.development-vpc.id
}

output "dev-subney-id" {
    value = aws_subnet.dev-subnet-1.id
}