remote_state {
  backend = "s3"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket               = "sandbox-terraform-state-${get_env("AWS_ACCOUNT_ID")}-s3-bucket"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    region               = get_env("AWS_REGION")
    encrypt              = true
    bucket_sse_algorithm = "AES256"
    dynamodb_table       = "sandbox-terraform-lock-dynamodb-table"
    s3_bucket_tags = {
      "Terraform"   = "true"
    }
    dynamodb_table_tags = {
      "Terraform"   = "true"
    }
  }
}

inputs = {
  account_id  = get_env("AWS_ACCOUNT_ID")
  region      = get_env("AWS_REGION")
  terraform_git_repository_name = get_env("TERRAFORM_GIT_REPOSITORY_NAME")
}
