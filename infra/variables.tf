variable "aws_region" {
  description = "Región de AWS donde se desplegarán los buckets S3"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente del despliegue: dev o prod"
  type        = string
  default     = "dev"
}
