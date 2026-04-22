# I 4 nameserver da copiare nel pannello OVH
output "nameservers" {
  description = "Copia questi 4 nameserver nel pannello OVH"
  value       = aws_route53_zone.main.name_servers
}

output "cloudfront_url" {
  description = "URL CloudFront (funziona anche senza dominio custom)"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "website_url" {
  description = "URL finale del sito con dominio custom"
  value       = "https://${var.domain_name}"
}