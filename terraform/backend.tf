# Terraform state file configuration - Stores terraform state file in bucket and locks it via DynamoDB

terraform {
  backend "s3" {
    bucket         = "secure-static-site-aws-tf-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-state-lock"
  }
}
