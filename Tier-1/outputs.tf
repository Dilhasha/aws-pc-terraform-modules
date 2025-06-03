output "region" {
  value = var.region
}
output "vpc_id" {
  value = module.vpc.vpc_id
}
output "cluster_name" {
  value = module.eks.cluster_name
}
output "db_hostname" {
  value = var.enable_tier_two ? module.rds.db_proxy_endpoint : module.rds.db_instance_endpoint
}
output "rds_root_secret_arn" {
  value = module.rds.db_root_secret_arn
}
output "rds_user_secret_arn" {
  value = var.user_db_secret_arn
}
output "rds_root_secret_name" {
  value = module.rds.rds_root_secret_name
}
output "lb_controller_role_name" {
  value = module.lb_controller_role.iam_role_arn
}
output "csi_secret_role_name" {
  value = module.csi_secret_role.iam_role_arn
}
output "csi_ebs_role_name" {
  value = module.csi_ebs_role.iam_role_arn
}
output "public_security_group_id" {
  value = module.vpc.public_security_group_id
}
output "ssm_parameter_read_only_role_arn" {
  value = module.ssm_parameter_read_only_role.iam_role_arn
}
