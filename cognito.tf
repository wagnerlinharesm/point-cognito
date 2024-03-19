provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket         = "point-terraform-state"
    key            = "point-cognito.tfstate"
    region         = "us-east-2"
    encrypt        = true
  }
}

resource "aws_cognito_user_pool" "cognito_user_pool" {
  name = "point"
  lambda_config {
    pre_sign_up = "arn:aws:lambda:us-east-2:644237782704:function:point_lambda_pre_sign_up"
  }
  password_policy {
    minimum_length = 6
    require_lowercase = false
    require_numbers = false
    require_symbols = false
    require_uppercase = false
  }
  mfa_configuration = "OFF"
}

resource "aws_cognito_user_pool_client" "point-app-client" {
  name = "point-cognito-app-client"
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["openid", "profile"]
  callback_urls = ["https://example.com/callback"]
  logout_urls = ["https://example.com/logout"]
  supported_identity_providers = ["COGNITO"]
  explicit_auth_flows = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH"]
}