module "ssh-key" {
  source         = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/EC2-SSH-Key?ref=UnitOfWork"
  region         = var.region
  project        = var.project
  environment    = var.environment
  tags           = var.default_tags
  application    = var.application
  ssh_public_key = var.ssh_public_key
}

module "vpc" {
  source             = "git::https://github.com/wso2/aws-cloud-terraform-modules.git//Network/VPC_Single?ref=main"
  region             = var.region
  project            = var.project
  environment        = var.environment
  application        = var.application
  default_tags       = var.default_tags
  vpc_cidr_range     = var.vpc_cidr_range
  public_subnets     = local.public_subnets
  app_subnets        = local.app_subnets
  database_subnets   = local.database_subnets
  management_subnets = local.management_subnets
  public_security_group_ingress_rules = flatten([
    for cidr in var.public_allow_cidrs : [{
      ip_protocol = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_block  = cidr
      },
      {
        ip_protocol = "tcp"
        from_port   = 443
        to_port     = 443
        cidr_block  = cidr
      },
    ]
  ])

  nat_redundancy     = false
  availability_zones = local.availability_zones
}

module "eks" {
  source                     = "git::https://github.com/wso2/aws-cloud-terraform-modules.git//Compute/EKS-Cluster?ref=main"
  region                     = var.region
  project                    = var.project
  environment                = var.environment
  application                = var.application
  default_tags               = var.default_tags
  cluster_subnet_ids         = module.vpc.app_subnets_id
  eks_endpoint_public_access = true
  eks_public_access_cidrs    = ["203.94.95.0/24", "112.135.230.102/32", "0.0.0.0/0"]
  k8s_version                = var.k8s_version
  access_entry = [
    {
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      principal_arn = module.management_vm_role.iam_role_arn
      type          = "cluster"
    },
    {
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      principal_arn = module.eks_management_role.iam_role_arn
      type          = "cluster"
    }
  ]
  eks_security_group_egress_rules = [
    {
      ip_protocol    = "-1"
      security_group = module.vpc.app_security_group_id
    },
  ]
  eks_security_group_ingress_rules = [
    {
      ip_protocol    = "-1"
      security_group = module.vpc.app_security_group_id
    },
    {
      ip_protocol    = "-1"
      security_group = module.vpc.management_security_group_id
    }
  ]  
}

module "nodegroup" {
  source       = "git::https://github.com/wso2/aws-cloud-terraform-modules.git//Compute/EKS-NodeGroup?ref=main"
  region       = var.region
  project      = var.project
  environment  = var.environment
  default_tags = var.default_tags
  node_group = {
    name                   = "application"
    disk_size              = 20
    ssh_key_name           = module.ssh-key.ssk_key_name
    vpc_security_group_ids = [module.vpc.app_security_group_id, module.eks.eks_security_group_id]
    eks_cluster_name       = module.eks.cluster_name
    node_role_arn          = module.eks_node_group_role.iam_role_arn
    subnet_ids             = module.vpc.app_subnets_id
    min_size               = 2
    max_size               = 2
    desired_size           = 2
    max_unavailable        = 2
    k8s_version            = var.k8s_version
    instance_types         = var.eks_instance_types
  }
}

module "rds" {
  source                = "git::https://github.com/wso2/aws-cloud-terraform-modules.git//DataBase/RDS_MySql?ref=main"
  region                = var.region
  project               = var.project
  environment           = var.environment
  application           = var.application
  default_tags          = var.default_tags
  db_subnet_ids         = module.vpc.database_subnets_id
  db_security_group_ids = [module.vpc.database_security_group_id]
  instance_class        = var.mysql_db_type
  engine_version        = "8.0"
  username              = "root"
  multi_az              = var.enable_tier_two ? true : false
  require_tls           = false
  deletion_protection   = false
  create_db_proxy       = var.enable_tier_two ? true : false
}

module "management_vm" {
  source             = "git::https://github.com/wso2/aws-cloud-terraform-modules.git//Compute/VM-Management?ref=main"
  region             = var.region
  project            = var.project
  environment        = var.environment
  application        = var.application
  default_tags       = var.default_tags
  ami_id             = var.management_ami_id
  ec2_instance_type  = "t3a.nano"
  root_volume_size   = 20
  iam_role_name      = module.management_vm_role.iam_role_name
  ssh_key_name       = module.ssh-key.ssk_key_name
  security_group_ids = [module.vpc.app_security_group_id]
  subnet_id          = module.vpc.app_subnets_id[0]
}
