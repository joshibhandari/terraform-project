
locals {
  max_subnet_length = max(
    length(var.private_subnets)
  )
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length 

  vpc_id = element(
    concat(
      aws_vpc_ipv4_cidr_block_association.this.*.vpc_id,
      aws_vpc.this.*.id,
      [""],
    ),
    0,
  )

  vpce_tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
  )
  
}
resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block                            = var.cidr
  instance_tenancy                      = var.instance_tenancy
  enable_dns_hostnames                  = var.enable_dns_hostnames
  enable_dns_support                    = var.enable_dns_support
  # enable_classiclink                  = var.enable_classiclink
  # enable_classiclink_dns_support      = var.enable_classiclink_dns_support
  assign_generated_ipv6_cidr_block      = var.enable_ipv6

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = var.create_vpc && length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0

  vpc_id                                = aws_vpc.this[0].id
  cidr_block                            = element(var.secondary_cidr_blocks, count.index)
}

resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this[0].id

  dynamic "ingress" {
    for_each = var.security_group_ingress
    content {
      self                              = lookup(ingress.value, "self", null)
      cidr_blocks                       = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks                  = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids                   = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
      security_groups                   = compact(split(",", lookup(ingress.value, "security_groups", "")))
      description                       = lookup(ingress.value, "description", null)
      from_port                         = lookup(ingress.value, "from_port", 0)
      to_port                           = lookup(ingress.value, "to_port", 0)
      protocol                          = lookup(ingress.value, "protocol", "-1")
    }
  }

  dynamic "egress" {
    for_each = var.security_group_egress
    content {
      self                              = lookup(egress.value, "self", null)
      cidr_blocks                       = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks                  = compact(split(",", lookup(egress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids                   = compact(split(",", lookup(egress.value, "prefix_list_ids", "")))
      security_groups                   = compact(split(",", lookup(egress.value, "security_groups", "")))
      description                       = lookup(egress.value, "description", null)
      from_port                         = lookup(egress.value, "from_port", 0)
      to_port                           = lookup(egress.value, "to_port", 0)
      protocol                          = lookup(egress.value, "protocol", "-1")
    }
  }

  tags = {
    Name = var.security_groups_name
  }
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "this" {
  count = var.create_vpc && var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format("%s", var.resource_name)
    },
    var.tags,
    var.igw_tags,
  )
  lifecycle {
    ignore_changes  = [tags, ]
    prevent_destroy = false
  }
}

################
# Public subnet
################
resource "aws_subnet" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 && (false == var.one_nat_gateway_per_az || length(var.public_subnets) >= length(var.azs)) ? length(var.public_subnets) : 0

  vpc_id                          = local.vpc_id
  cidr_block                      = element(concat(var.public_subnets, [""]), count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch         = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation = var.public_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.public_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.public_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    {
      "Name" = format(
        "%s-${var.public_subnet_suffix}-%s",
        var.resource_name,
        element(var.azs, count.index),
      )
      # ,
      # "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "shared",
      # "kubernetes.io/role/elb"                            = "1"
    },
    var.tags,
    var.public_subnet_tags,
  )
  lifecycle {
    ignore_changes  = [tags, ]
    prevent_destroy = false
  }
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count = var.create_vpc && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  vpc_id                          = local.vpc_id
  cidr_block                      = var.private_subnets[count.index]
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  assign_ipv6_address_on_creation = var.private_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.private_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.private_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    {
      "Name" = format(
        "%s-${var.private_subnet_suffix}-%s",
        var.resource_name,
        element(var.azs, count.index),
      )
      # ,
      # "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "shared",
      # "kubernetes.io/role/internal-elb"                   = "1"
    },
    var.tags,
    var.private_subnet_tags,
  )
  lifecycle {
    ignore_changes  = [tags, ]
    prevent_destroy = false # prevent destroy

  }
}

################
# Publiс routes
################
resource "aws_route_table" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}", var.resource_name)
    },
    var.tags,
    var.public_route_table_tags,
  )
  lifecycle {
    ignore_changes  = [tags, ]
    prevent_destroy = false
  }
}

resource "aws_route" "public_internet_gateway" {
  count = var.create_vpc && var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

#################
# Private routes
# There are as many routing tables as the number of NAT gateways
#################
resource "aws_route_table" "private" {
  count = var.create_vpc && local.max_subnet_length > 0 ? local.nat_gateway_count : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = var.single_nat_gateway ? "${var.resource_name}-${var.private_subnet_suffix}" : format(
        "%s-${var.private_subnet_suffix}-%s",
        var.resource_name,
        element(var.azs, count.index),
      )
    },
    var.tags,
    var.private_route_table_tags,
  )
  lifecycle {
    ignore_changes  = [tags, ]
    prevent_destroy = false
  }
}

resource "aws_route" "private_nat_gateway" {
  count = var.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

##########################
# Route table association
##########################
resource "aws_route_table_association" "private" {
  count = var.create_vpc && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(
    aws_route_table.private.*.id,
    var.single_nat_gateway ? 0 : count.index,
  )
}

resource "aws_route_table_association" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

locals {
  nat_gateway_ips = split(
    ",",
    var.reuse_nat_ips ? join(",", var.external_nat_ip_ids) : join(",", aws_eip.nat.*.id),
  )
}

resource "aws_eip" "nat" {
  count = var.create_vpc && var.enable_nat_gateway && false == var.reuse_nat_ips ? local.nat_gateway_count : 0

  # vpc = true
  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.eip_name,
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.tags,
    var.nat_eip_tags,
  )
}

resource "aws_nat_gateway" "this" {
  count = var.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    aws_subnet.public.*.id,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.nat_name,
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.nat_tags,
    var.nat_gateway_tags,
  )

  depends_on = [aws_internet_gateway.this]
}