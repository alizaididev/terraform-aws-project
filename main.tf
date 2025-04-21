provider "aws" {
  region = "eu-central-1b"
}


## VPC AND SUBNET SETUP CODE

resource "aws_vpc" "my_appvpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

## Modules in terraform
module "myapp-subnet" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  availability_zone = var.availability_zone
  env_prefix = var.env_prefix
  vpc_id = var.aws_vpc.my_appvpc.id
  default_route_table_id = aws_vpc.my_appvpc.default_route_table_id
}

module "myapp-webserver" {
  source = "./modules/webserver"
  vpc_id = var.aws_vpc.my_appvpc.id
  my_ip = var.my_ip
  env_prefix = var.env_prefix
  public_key_location = var.public_key_location
  instance_type = var.instance_type
  subnet_id = module.myapp-subnet.subnet ## why did we use module.------------ instead of var.--------- ASK GENAI TOOL FOR CONCEPT
  availability_zone = var.availability_zone
}