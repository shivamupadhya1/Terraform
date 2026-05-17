# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public Subnets (Tier 1 — ALB)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${var.azs[count.index]}"
    Tier = "public"
  })
}

# Private App Subnets (Tier 2 — EC2/ASG)
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-app-${var.azs[count.index]}"
    Tier = "private-app"
  })
}

# Private Data Subnets (Tier 3 — RDS)
resource "aws_subnet" "private_data" {
  count             = length(var.private_data_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_data_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-data-${var.azs[count.index]}"
    Tier = "private-data"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${count.index}"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.this]

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${count.index}"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private App Route Tables (one per NAT or shared single NAT)
resource "aws_route_table" "private_app" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_app_subnets)) : 1
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-app-rt-${count.index}"
  })
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.private_app_subnets)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private_app[0].id : aws_route_table.private_app[count.index].id
}

# Private Data Route Table (no internet — maximum isolation for RDS)
resource "aws_route_table" "private_data" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-data-rt"
  })
}

resource "aws_route_table_association" "private_data" {
  count          = length(var.private_data_subnets)
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private_data.id
}

