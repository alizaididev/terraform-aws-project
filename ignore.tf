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

# resource "aws_subnet" "my_appsubnet" {
#   vpc_id = aws_vpc.my_appvpc.id
#   cidr_block = var.subnet_cidr_block
#   tags = {
#     Name: "${var.env_prefix}-subnet-1"
#   }
# }

# ## ROUTE AND INTERNET GATEWAY SETUP CODE

# resource "aws_internet_gateway" "myapp_internet_gateway" {
#   vpc_id = aws_vpc.my_appvpc.id

#   tags = {
#     Name: "${var.env_prefix}-igw-a"
#   }
# }


# resource "aws_route_table" "myapp_routetable" {
#   vpc_id = aws_vpc.my_appvpc.id

#   route = {
#     cidr_block = ""
#     gateway_id = myapp_internet_gateway.id
#   }

#   tags = {
#     Name: "${var.env_prefix}-rtb-a"
#   }
# }

## AWS ROUTE TABLE SUBNET ASSOCIATION

resource "aws_route_table_association" "subnet_rtb_a" {
  subnet_id = aws_subnet.my_appsubnet.id
  route_table_id = aws_route_table.myapp_routetable.id
}

## Default Vpc Main if we do not want to set up custom vpc 

# resource "aws_default_route_table" "main-rtb" {
#   default_route_table_id = aws_vpc.my_appvpc.myapp_internet_gateway.id

#   route = {
#     cidr_block = "10.0.0.0"
#     gateway_id = myapp_internet_gateway.id
#   }

#   tags = {
#     Name: "${var.env_prefix}main-rtb-a"
#   }
# }

## SECURITY GROUP CONFIGURATION

resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.my_appvpc.id

### Ingress is used for incoming website traffic rules setup like port to allow and deny and other resouces configuration, ## in cidr block we define which ips or ip range are allowed to access our app inside vpc for this example here we are using our local ip

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    ## in cidr block we define which ips or ip range are allowed to access our app inside vpc for this example here we are using our local ip
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }


  tags = {
     Name: "${var.env_prefix}sg-a"
  }
}

## Code for most recent amazon ami image so here instead of resource we use data as image gets upadtes so when it 
## get updated its ami id changes so instead of hard coding it in resource we use data and store ami ami value there"
data "aws_ami" "most_recent_ami" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "amazon" #use name of the image here
    values = ["*"] #paste the copied image name here
  }

  ## we can addd as much much filters as required according to our need for the resources 
  filter {
    name   = virtualiztaion-type
    values = ["hvm"]
  }
}


## SSH KEY PAIR AUTOMATION , as we do manual work by adding ssh key or pem file pulic priv key so to automate it

resource "aws_key_pair" "server_key_pair" {
  key_name = "server-key"
  public_key = file(var.public_key_location) ## we put publice key here either by generating it locally and then paste it here aws will ssh into it and also create private key for this, so we will store its value inside a variable
}

## EC2 Instance Code
resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.most_recent_ami.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.my_appsubnet.id
  security_groups = [aws_security_group.myapp-sg]
  availability_zone = var.availability_zone

  associate_public_ip_address = true ### for ssh from remote we write this 
  key_name = aws_key_pair.server_key_pair.key_name ## here we also wrote attribute name of the ssh key pair which is key_name ### pem file to ssh into our instance securely , one we download the pem file its required to move it from downloads folder to ssh plus set the permission on it 400 so that no one can access or make changes in it.
  

## another of using entry level scripts is by entering the location as we did above in the public key association but we do not create variable here we create a file here like entry-script.sh in this case.

#user_data = file(entry-script.sh) ### passing the data to ec2

## another way of doing this is as below:

  # user_data = <<EOF
  #                 #!bin/bash
  #                 sudo apt update/sudo apt install docker
  #                 sudo systemctl start docker
  #                 sudo usermod -aG docker ec2-user
  #                 docker run -p 8080:80 nginx
  #               EOF    

user_data_replace_on_change = true

### connection is used by provisioners , in this example we have 2 provisioner so connection uses two provisioners in this case 
connection {
  type = "ssh"
  host = self.public_ip
  user = "ec2-user"
  private_key = file(var.priv_key_location)
}


### file provisioner >> copy files or directory from local to newly created resources
### source >> source file or folder
### destination >> absolute path 
provisioner "file" {
  source = "entry-script.sh"
  destination = "home/ec2-user/entry-script-on-ec2.sh"
}

provisioner "remote-exec" {    ## remote exec >> connect via ssh using terraform
  #inline = ["home/ec2-user/entry-script.sh-on-ec2.sh"] ## theres a more cleaner way of using it! by using script keyword
  script = "entry-script.sh"
}


## Local provisioner >> invokes a local executeable after a resource is created , LOCALLY NOT ON CREATED RESOURCE!
### IMP >>>> BUT WE USE LOCAL PROVIDER FOR LOCAL TASKS AS PROVISIONER IS NOT RECOMMENDED BY TF ALSO BREAKS THE CONCEPT OF 
### ITEMPOTENCY AND CURRENT-DESIRED STATE IN TERRAFORM
provisioner "local-exec" {
  command = "echo ${self.public_ip} > output.txt"
}

  tags = {
     Name: "${var.env_prefix}-server"
  }
}
  
