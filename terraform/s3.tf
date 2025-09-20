# Website bucket (private)
resource "aws_s3_bucket" "site" {
  bucket = var.site_bucket_name
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Allow CloudFront (OAC) to read objects from this bucket
data "aws_iam_policy_document" "allow_cf_oac" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"] # <- identifiers REQUIRED
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.allow_cf_oac.json
}

# Upload local build files
locals {
  artifact_dir = var.artifact_dir
  files        = fileset(local.artifact_dir, "**")
  mime_by_ext = {
    html = "text/html", js = "application/javascript", mjs = "application/javascript",
    css  = "text/css", json = "application/json", svg = "image/svg+xml", png = "image/png",
    jpg  = "image/jpeg", jpeg = "image/jpeg", gif = "image/gif", webp = "image/webp",
    ico  = "image/x-icon", txt = "text/plain", map = "application/json", wasm = "application/wasm"
  }
}

resource "aws_s3_object" "site_files" {
  for_each = { for f in local.files : f => f }
  bucket   = aws_s3_bucket.site.id
  key      = each.value
  source   = "${local.artifact_dir}/${each.value}"
  etag     = filemd5("${local.artifact_dir}/${each.value}")
  content_type = lookup(
    local.mime_by_ext,
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "application/octet-stream"
  )
}
