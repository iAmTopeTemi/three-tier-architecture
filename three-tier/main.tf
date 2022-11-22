
terraform {

  backend "s3" {

    bucket         = "three-tier-architecture-temi"
    key            = "path/env/3-tier"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}

locals {
  vpc_id = aws_vpc.three_tier_archi.id
  azs    = data.aws_availability_zones.available.names
}


data "aws_availability_zones" "available" {
  state = "available"
}

#creating vpc
resource "aws_vpc" "three_tier_archi" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "three-tier-archi"
  }
}

#creating igw
resource "aws_internet_gateway" "igw_three_tier_archi" {
  vpc_id = local.vpc_id

  tags = {
    Name = "igw_three_tier"
  }
}

#creating public subnets
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_cidr)
  vpc_id                  = local.vpc_id
  cidr_block              = var.public_cidr[count.index]
  availability_zone       = element(slice(local.azs, 0, 2), count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_${count.index + 1}"
  }
}

#creating private subnets
resource "aws_subnet" "private_subnet" {
  count             = length(var.private_cidr)
  vpc_id            = local.vpc_id
  cidr_block        = var.private_cidr[count.index]
  availability_zone = element(slice(local.azs, 0, 2), count.index)

  tags = {
    Name = "private_subnet_${count.index + 1}"
  }
}

#creating database subnets
resource "aws_subnet" "database_subnet" {
  count             = length(var.database_cidr)
  vpc_id            = local.vpc_id
  cidr_block        = var.database_cidr[count.index]
  availability_zone = element(slice(local.azs, 0, 2), count.index)

  tags = {
    Name = "database_subnet_${count.index + 1}"
  }
}

#creating public route table
resource "aws_route_table" "public_rt" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_three_tier_archi.id
  }

  tags = {
    Name = "custom_rt_public_3_tier"
  }
}

#creating subnet association

resource "aws_route_table_association" "assoc_for_pub-sn" {
  count          = length(var.public_cidr) #so for every pub sn, associate the RT instead of duplicating code
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

#creating eip

resource "aws_eip" "eip_for_three_tier" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw_three_tier_archi] #i want nat to be created first

}

#creating nat gw

resource "aws_nat_gateway" "nat_gw_for_three_tier" {
  allocation_id = aws_eip.eip_for_three_tier.id
  subnet_id     = aws_subnet.public_subnet[0].id #to create in only on subnet

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw_three_tier_archi]

}

#creating default rt

resource "aws_default_route_table" "default_rt" {
  default_route_table_id = aws_vpc.three_tier_archi.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_for_three_tier.id
  }

  tags = {
    Name = "defaultRT"
  }
}