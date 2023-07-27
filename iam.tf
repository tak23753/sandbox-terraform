# ---------------------------------------------------------
# ID Provider
# ---------------------------------------------------------
data "http" "github_actions_openid_configuration" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

data "tls_certificate" "github_actions" {
  url = jsondecode(data.http.github_actions_openid_configuration.response_body).jwks_uri
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

# ---------------------------------------------------------
# Terraform
# ---------------------------------------------------------

data "aws_iam_policy_document" "github_actions_terraform_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.terraform_git_repository_name}:*"
      ]
    }
  }
}

data "aws_iam_policy" "administrator_access" {
  name = "AdministratorAccess"
}

resource "aws_iam_role" "github_actions_terraform" {
  name               = "sandbox-github-actions-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_terraform_assume.json

  tags = {
    Name = "sandbox-github-actions-terraform-role"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = data.aws_iam_policy.administrator_access.arn
}
