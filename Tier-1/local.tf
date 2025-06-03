

locals {
  availability_zones = slice(data.aws_availability_zones.availability_zones.names, 0, var.az_distribution)

  vpc_mask       = tonumber(split("/", var.vpc_cidr_range)[1])
  mgt_newBits    = 29 - var.az_distribution - local.vpc_mask
  db_newBits     = 28 - var.az_distribution - local.vpc_mask
  public_newBits = 28 - var.az_distribution - local.vpc_mask
  app_newBits    = 24 - var.az_distribution - local.vpc_mask

  subnets = cidrsubnets(var.vpc_cidr_range, local.mgt_newBits, local.db_newBits, local.public_newBits, local.app_newBits)

  # /24 prefix length for app subnets
  app_subnets = [for i in range(var.az_distribution) : cidrsubnet(local.subnets[3], 24 - tonumber(split("/", local.subnets[3])[1]), i)]
  # /27 prefix length for database subnets
  database_subnets = [for i in range(var.az_distribution) : cidrsubnet(local.subnets[1], 27 - tonumber(split("/", local.subnets[1])[1]), i)]
  # /27 prefix length for public subnets
  public_subnets = [for i in range(var.az_distribution) : cidrsubnet(local.subnets[2], 27 - tonumber(split("/", local.subnets[2])[1]), i)]
  # /28 prefix length for management subnets
  management_subnets = [for i in range(var.az_distribution) : cidrsubnet(local.subnets[0], 28 - tonumber(split("/", local.subnets[0])[1]), i)]
  ecr_registry_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}
