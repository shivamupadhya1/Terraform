provider "aws" {
  region = var.region
}

resource "aws_vpc" "DevOps-VPC" {
  cidr_block = var.cidr_range
}

resource "aws_internet_gateway" "DevOpsigw" {
  vpc_id = aws_vpc.DevOps-VPC.id

}

resource "aws_subnet" "Devops-pub-sn" {
    vpc_id = aws_vpc.DevOps-VPC.id
    cidr_block = var.cidr_pub_sn
    availability_zone = var.az_pub
    tags ={
        Name= "DevOps-pub-sn"
    }
}

resource "aws_subnet" "Devops-pvt-sn" {
    vpc_id = aws_vpc.DevOps-VPC.id
    cidr_block = var.cidr_pvt_sn
     availability_zone = var.az_pvt
    tags ={
        Name= "DevOps-pvt-sn"
    }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.DevOps-VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.DevOpsigw.id
    }
    tags ={
        Name= "DevOps-pub-rt"
    }
  
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.DevOps-VPC.id
    tags ={
        Name= "DevOps-pvt-rt"
    }
  
}

resource "aws_route_table_association" "pvt_sn_pvt_rt" {
  subnet_id = aws_subnet.Devops-pvt-sn.id
  route_table_id = aws_route_table.private_rt.id

}

resource "aws_route_table_association" "pub_sn_pub_rt" {
  subnet_id = aws_subnet.Devops-pub-sn.id
  route_table_id = aws_route_table.public_rt.id

}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "DevOps-nat-eip"
  }
}
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.Devops-pub-sn.id
  tags = {
    Name = "DevOps-nat-gw"
  }
}


resource "aws_route" "pvt_rt_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

####################################
# Security Groups
####################################
# Allow SSH & HTTP for Public Instance

resource "aws_security_group" "public_sg" {
  name        = "DevOps-public-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.DevOps-VPC.id

  ingress {
    description = "Allow SSH from my computer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOps-public-sg"
  }
}
# Allow only SSH from Public Instance (Jump Host) for Private Instance
resource "aws_security_group" "private_sg" {
  name        = "DevOps-private-sg"
  description = "Allow SSH only from public instance"
  vpc_id      = aws_vpc.DevOps-VPC.id

  ingress {
    description     = "Allow SSH from Public Subnet SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOps-private-sg"
  }
}

resource "aws_key_pair" "devops_key" {
  key_name   = "devops-key"
  public_key = file("D:/DevOPS/terraform-script/keys/devops-key.pub")

}



# Public Instance
resource "aws_instance" "public_instance" {
  ami           = var.ami_id   # e.g. Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.Devops-pub-sn.id
  key_name      = aws_key_pair.devops_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = {
    Name = "DevOps-public-instance"
  }
}

# Private Instance
resource "aws_instance" "private_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.Devops-pvt-sn.id
  key_name      = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "DevOps-private-instance"
  }
}

