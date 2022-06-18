# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "AKIASECVIBJHMLGIE23Y"
  secret_key = "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"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name= "main-vpc"
 }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

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


resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Main"
   }
  }

  resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_security_group" "allow_traffic" {
  name        = "allow traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main.id


  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 ingress {
    description      = "docker"
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
resource "aws_network_interface" "WEB-SERVER" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_traffic.id]
  }

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.WEB-SERVER.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

resource "aws_instance" "web" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t3.micro"
  availability_zone = "us-east-1a"
  key_name = "newkey"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.WEB-SERVER.id
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
