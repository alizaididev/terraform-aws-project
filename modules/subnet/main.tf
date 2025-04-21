resource "aws_subnet" "myapp-subnet" {
  vpc_id = var.vpc_id
  cidr_block = var.subnet_cidr_block
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

## ROUTE AND INTERNET GATEWAY SETUP CODE

resource "aws_internet_gateway" "myapp_internet_gateway" {
  vpc_id = var.vpc_id

  tags = {
    Name: "${var.env_prefix}-igw-a"
  }
}


resource "aws_route_table" "myapp_routetable" {
  vpc_id = var.vpc_id  # Required parameter instead of default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"  # Must specify a valid CIDR
    gateway_id = aws_internet_gateway.myapp_internet_gateway.id  # Proper reference
  }

  tags = {
    Name = "${var.env_prefix}-rtb-a"  # Use = instead of :
  }
}
