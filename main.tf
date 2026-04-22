resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "demo-oac"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow_cf" {
  bucket = aws_s3_bucket.bucket.id
  depends_on = [ aws_s3_bucket_public_access_block.block ]
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFront",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "${aws_s3_bucket.bucket.arn}/*"
      Condition ={
        StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
        }
      }
    }
  ]
})
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  for_each = fileset("${path.module}/file_sito","**/*")
  key    = each.value
  source = "${path.module}/file_sito/${each.value}"

  etag = filemd5("${path.module}/file_sito/${each.value}")

  content_type = lookup({
    "html" = "text/html",
    "css" = "text/css"
  }, split(".", each.value)[length(split(".",each.value)) - 1], "application/octet-stream")
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

    aliases = [var.domain_name]   # ← dice a CloudFront di rispondere per il tuo dominio

  viewer_certificate {
    # Sostituisce cloudfront_default_certificate = true
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"   # standard moderno, gratuito
    minimum_protocol_version = "TLSv1.2_2021"
  }

}

resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_acm_certificate" "cert" {
  provider = aws.us_east_1
  domain_name = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider = aws.us_east_1
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name = var.domain_name
  type = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}