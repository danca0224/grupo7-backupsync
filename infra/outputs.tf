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

output "sns_topic_alertas" {
  description = "SNS Topic para alertas del Grupo 7"
  value       = aws_sns_topic.alertas.arn
}

output "cloudwatch_alarm_name" {
  description = "Nombre de la alarma CloudWatch de objetos S3"
  value       = aws_cloudwatch_metric_alarm.alarma_numero_objetos.alarm_name
}
