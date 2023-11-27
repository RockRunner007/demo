resource "aws_iam_policy" "ecr-ci-user" {
  name        = "ecr-power-dev"
  path        = "/"
  description = ""
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:CreateRepository",
          "ecr:DescribeRepositories",
          "ecr:GetAuthorizationToken",
          "ecr:SetRepositoryPolicy"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_user" "ecr-ci-user" {
  name = "ecr-ci-user-dev"
  path = "/"
}

resource "aws_iam_user_policy_attachment" "ecr-ci-user" {
  user       = aws_iam_user.ecr-ci-user.name
  policy_arn = aws_iam_policy.ecr-ci-user.arn
}

resource "aws_secretsmanager_secret" "ecr-ci-user-access-key" {
  name = aws_iam_user.ecr-ci-user.name
}

resource "aws_secretsmanager_secret_version" "ecr-ci-user-access-key" {
  secret_id = aws_secretsmanager_secret.ecr-ci-user-access-key.id
  secret_string = jsonencode({
    "access_key_id"     = aws_iam_access_key.ecr-ci-user-access-key-12-10-2021.id,
    "secret_access_key" = aws_iam_access_key.ecr-ci-user-access-key-12-10-2021.secret
  })
}

resource "aws_iam_access_key" "ecr-ci-user-access-key-12-10-2021" {
  user = aws_iam_user.ecr-ci-user.name
}
