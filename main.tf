#Crear la VPC en la zona CNBD
resource "aws_vpc" "vpc" {
  cidr_block = var.dmz-cidr
  tags = {
    Name = "VPC-ZonaDMZ"
  }
}
#Obtener todas las zonas disponibles en la region
data "aws_availability_zones" "available" {
  state = "available"
}

#Crear las subnets publicas
resource "aws_subnet" "public-subnets" {
  count = length(var.public-subnets)
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public-subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % 2]
  map_public_ip_on_launch = false
  tags = {
    Name = "Subnet-publica${count.index + 1}"
  }
}

#Crear las subnets para la capa webapp
resource "aws_subnet" "private-subnets" {
  count                   = length(var.private-subnets)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private-subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index % 2]
  map_public_ip_on_launch = false
  tags = {
    Name = "Subnet-privada-${count.index + 1}"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  count = length(var.public-subnets) > 0 ? 1:0
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "dmz-igw"
  }
}

# NAT gateway - Para que las subredes privadas tengas acceso a internet para descargar paquetes o otros
resource "aws_eip" "eip" {
  count      = var.nat-required && length(var.public-subnets) > 0 ? 1:0
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_nat_gateway" "nat-gw" {
  count         = var.nat-required && length(var.public-subnets) > 0 ? 1:0
  subnet_id     = aws_subnet.public-subnets[0].id
  allocation_id = aws_eip.eip[0].id
}

# Tabla de ruteo para subnets publicas
resource "aws_route_table" "public-rt" {
  count = length(var.public-subnets)
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
  tags = {
    Name = "Route-publico"
  }
}
#Tabla de ruteo para subnets privadas (webapp)
resource "aws_route_table" "private-rt" {
  count = length(var.private-subnets)
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw[0].id
  }
  tags = {
    Name = "Route-privada"
  }
}
# Asociación de tablas de ruteo con subnets publicas
resource "aws_route_table_association" "associate-public-rt" {
  count = length(var.public-subnets)
  subnet_id = element(aws_subnet.public-subnets.*.id, count.index)
  route_table_id = aws_route_table.public-rt[0].id
}
# Asociación de tablas de ruteo con subnets privadas
resource "aws_route_table_association" "associate-private-rt" {
  count = length(var.private-subnets)
  subnet_id = element(aws_subnet.private-subnets.*.id, count.index)
  route_table_id = aws_route_table.private-rt[0].id
}