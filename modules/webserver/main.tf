resource "aws_default_security_group" "default-sg" {
#   name = "myapp-sg"
  vpc_id = var.vpc_id

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
    name   = "name" #use name of the image here
    values = ["var.image_name"] #paste the copied image name here
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

  subnet_id = var.subnet_id
  security_groups = [aws_default_security_group.default-sg.id] ## why didnt we use var method here and preferred this ASK GEN AI TOOL TO CLEAR THE CONCEPT ABOUT IT! 
  availability_zone = var.availability_zone

  associate_public_ip_address = true ### for ssh from remote we write this 
  key_name = aws_key_pair.server_key_pair.key_name ## here we also wrote attribute name of the ssh key pair which is key_name ### pem file to ssh into our instance securely , one we download the pem file its required to move it from downloads folder to ssh plus set the permission on it 400 so that no one can access or make changes in it.
  
user_data_replace_on_change = true


  tags = {
     Name: "${var.env_prefix}-server"
  }
}
  
