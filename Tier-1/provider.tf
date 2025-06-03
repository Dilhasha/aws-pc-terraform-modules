terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "Deployment" = "PINC"
      "Name"       = "PINC-TestEKS"
    }
  }
}
