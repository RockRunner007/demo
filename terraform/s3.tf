data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

resource "aws_kms_key" "key" {
  deletion_window_in_days = 7
  policy = jsonencode({
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Resource = "*"
        Sid      = "AllowKeyAdministration"
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Effect = "Allow"
        Resource = "*"
        Sid      = "AllowS3Uploads"
      }
    ]
    Version = "2012-10-17"
  })
}
resource "aws_s3_bucket" "bucket" {
  bucket = "incoming-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3control_multi_region_access_point" "incoming" {
  details {
    name = "incoming"

    region {
      bucket = aws_s3_bucket.bucket.id
    }
  }
}
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonHttpsAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "${aws_s3_bucket.bucket.arn}",
          "${aws_s3_bucket.bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Sid    = "AllowRemoteAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.bucket.arn}",
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      }
    ]
  })
}
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
resource "aws_s3control_multi_region_access_point_policy" "incoming" {
  details {
    name = element(split(":", aws_s3control_multi_region_access_point.incoming.id), 1)
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "incoming"
          Effect = "Allow"
          Principal = {
            AWS = [
              data.aws_caller_identity.current.account_id
            ]
          }
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          "Resource" = "arn:aws:s3::${data.aws_caller_identity.current.account_id}:accesspoint/${aws_s3control_multi_region_access_point.incoming.alias}/object/*"
        }
      ]
    })
  }
}
