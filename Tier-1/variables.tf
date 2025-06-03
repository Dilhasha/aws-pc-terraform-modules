variable "project" {
  type        = string
  description = "Project"
}
variable "environment" {
  type        = string
  description = "Environment"
}
variable "region" {
  type        = string
  description = "Region"
}
variable "application" {
  type        = string
  description = "Application"
}
variable "default_tags" {
  type        = map(string)
  description = "Map of default tags to apply to all resources deployed during Private Cloud deployment."
}
variable "enable_tier_two" {
  type        = bool
  description = "Enable Tier two."
}
variable "az_distribution" {
  type        = number
  default     = 2
  description = "Number of AZ that subnets should be created. Should be align with the number of AZ in the region."
}
variable "vpc_cidr_range" {
  type        = string
  description = "CIDR range for VPC created during Private Cloud deployment."
  default     = "10.0.0.0/16"
}
variable "k8s_version" {
  type        = string
  description = "K8s version for Private Cloud deployment."
}
variable "mysql_db_type" {
  type        = string
  description = "RDS Database type for Private Cloud deployment."
}
variable "eks_instance_types" {
  type        = list(string)
  default     = ["t3a.medium"]
  description = "EKS instance type for Private Cloud deployment."
}
variable "management_ami_id" {
  type        = string
  description = "AMI id for management instance."
}
variable "public_allow_cidrs" {
  type        = list(string)
  description = "List of CIDR ranges allow to access Private Cloud deployment."
}
variable "user_db_secret_arn" {
  type        = string
  description = "ARN of the DB user secret. Which used to access Database by APIM application."
}
variable "ssh_public_key" {
  type        = string
  description = "SSH public key as a sting."
}
variable "k8s_repo" {
  type        = string
  description = "Git repo name storing APIM application K8/HELM artifacts (org/repo)"
}
variable "git_oidc_provider_arn" {
  type        = string
  description = "Arn of the github oidc provider."
}

# CI
variable "github_personal_access_token" {
  type        = string
  description = "Github Org Personal Access Token"
}

variable "github_org_name" {
  description = "Github Org Name"
  type        = string
}

variable "ci_project_integration_build_repo_name" {
  description = "The name of the CI project IS build repo"
  type        = string
}

variable "devops_ci_project_build_branch" {
  description = "The name of the CI project build repo"
  type        = string
}

variable "ci_bucket_name" {
  description = "S3 bucket name for codepipeline"
  type        = string
  default = "test-bucket"
}

variable "devops_ci_project_integration_build_yml_path" {
  description = "The path of the CI project IS build yml"
  type        = string
  default     = "ci-pipelines/azure-pipeline-001.yml"
}

variable "cd_project_integration_build_repo_name" {
  description = "The name of the CI project IS build repo"
  type        = string
}

variable "devops_cd_project_build_branch" {
  description = "The name of the CI project build repo"
  type        = string
}

variable "cd_bucket_name" {
  description = "S3 bucket name for codepipeline for CD"
  type        = string
  default = "test-bucket"
}

variable "integration_bucket_name" {
  description = "S3 bucket name for codepipeline for integration"
  type        = string
  default = "test-bucket"
}

variable "admin_role" {
  type        = string
  description = "Admin role ARN to access AWS resources."
}
