terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-south-1"
}

provider "aws" {
  alias = "us_east_1"
  region = "us-east-1"
}