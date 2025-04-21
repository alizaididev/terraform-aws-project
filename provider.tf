terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.94.1"
    }
    linode = {
      source = "linode/linode"
      version = "2.37.0"
    }
  }
}