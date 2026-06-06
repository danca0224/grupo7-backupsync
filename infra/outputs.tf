output "bucket_principal" {
  description = "Nombre del bucket principal donde se suben los archivos"
  value       = aws_s3_bucket.principal.bucket
}

output "bucket_respaldo" {
  description = "Nombre del bucket de respaldo donde se replican los archivos"
  value       = aws_s3_bucket.respaldo.bucket
}

output "replication_role_arn" {
  description = "ARN del rol IAM usado por S3 para replicar objetos"
  value       = aws_iam_role.replication_role.arn
}
