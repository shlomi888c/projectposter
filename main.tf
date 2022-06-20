# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

# Creating VPC

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name= "main-vpc" 
 }
}

# create internet gateaway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# Making  Route Table

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Main"
  }
}

# Creating Subnet 1

resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Main"
   }
  }

# Associating the Subnet 1 with the  Route Table 1

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route-table.id
}

# Creating Security Group to Allow webapp Traffic and ssh

resource "aws_security_group" "allow_traffic" {
  name        = "allow traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "webapp"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  
  }
 ingress {
    description      = "webapp"
    from_port        = 5001
    to_port          = 5001
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  
  }
 ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_TRAFFIC"
  }
}

# create a network interface with an ip in the subnet that was created

resource "aws_network_interface" "webapp" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_traffic.id]
  }

# assgin an Elastic IP to the network interface

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webapp.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}


# create linux 2 ec2 and run

resource "aws_instance" "web" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
  availability_zone = "us-east-1a"
  key_name = "newkey"
   
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.webapp.id
  }

  user_data = <<-EOF
              #! /bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo systemctl enable docker
              sudo curl -SL https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              sudo yum install git -y
              sudo git clone https://github.com/shlomi888c/projectposter.git 
              cd projectposter
              sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
              sudo docker-compose build
              sudo docker-compose up
              EOF 
  tags = {
   Name = "Main-ec2"
  }
}
