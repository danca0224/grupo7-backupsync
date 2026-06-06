data "aws_caller_identity" "current" {}

locals {
  account_id       = data.aws_caller_identity.current.account_id
  bucket_principal = "grupo7-principal-${local.account_id}-${var.environment}"
  bucket_respaldo  = "grupo7-respaldo-${local.account_id}-${var.environment}"
}

resource "aws_s3_bucket" "principal" {
  bucket = local.bucket_principal

  tags = {
    Name        = "grupo7-principal"
    Environment = var.environment
    Project     = "BackupSync"
    Group       = "7"
  }
}

resource "aws_s3_bucket" "respaldo" {
  bucket = local.bucket_respaldo

  tags = {
    Name        = "grupo7-respaldo"
    Environment = var.environment
    Project     = "BackupSync"
    Group       = "7"
  }
}

resource "aws_s3_bucket_public_access_block" "bloqueo_principal" {
  bucket = aws_s3_bucket.principal.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "bloqueo_respaldo" {
  bucket = aws_s3_bucket.respaldo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning_principal" {
  bucket = aws_s3_bucket.principal.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "versioning_respaldo" {
  bucket = aws_s3_bucket.respaldo.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "replication_role" {
  name = "grupo7-replication-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "grupo7-replication-role"
    Environment = var.environment
    Project     = "BackupSync"
    Group       = "7"
  }
}

resource "aws_iam_role_policy" "replication_policy" {
  name = "grupo7-replication-policy-${var.environment}"
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadSourceBucketConfiguration"
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.principal.arn
        ]
      },
      {
        Sid    = "AllowReadSourceObjectVersions"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionTagging"
        ]
        Resource = [
          "${aws_s3_bucket.principal.arn}/*"
        ]
      },
      {
        Sid    = "AllowReplicationToDestinationBucket"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = [
          "${aws_s3_bucket.respaldo.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "replicacion" {
  depends_on = [
    aws_s3_bucket_versioning.versioning_principal,
    aws_s3_bucket_versioning.versioning_respaldo,
    aws_iam_role_policy.replication_policy
  ]

  bucket = aws_s3_bucket.principal.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "grupo7-replicacion-total"
    status = "Enabled"

    filter {
      prefix = ""
    }

    destination {
      bucket        = aws_s3_bucket.respaldo.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Disabled"
    }
  }
}

# ============================================================
# PUNTOS EXTRA - LIFECYCLE EN BUCKET DE RESPALDO
# Mover objetos a GLACIER_IR a los 30 días y eliminarlos a los 90
# ============================================================

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_respaldo" {
  bucket = aws_s3_bucket.respaldo.id

  rule {
    id     = "grupo7-lifecycle-respaldo"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = 90
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.versioning_respaldo
  ]
}

# ============================================================
# PUNTOS EXTRA - SNS PARA RECIBIR ALERTAS DE CLOUDWATCH
# ============================================================

resource "aws_sns_topic" "alertas" {
  name = "grupo7-alertas-${var.environment}"

  tags = {
    Name        = "grupo7-alertas"
    Environment = var.environment
    Project     = "BackupSync"
    Group       = "7"
  }
}

# ============================================================
# PUNTOS EXTRA - ALARMA CLOUDWATCH
# Alerta cuando el bucket principal supera 100 objetos
# ============================================================

resource "aws_cloudwatch_metric_alarm" "alarma_numero_objetos" {
  alarm_name          = "grupo7-alarma-objetos-s3-${var.environment}"
  alarm_description   = "Alerta cuando el bucket principal supera 100 objetos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 100
  period              = 86400
  statistic           = "Average"
  namespace           = "AWS/S3"
  metric_name         = "NumberOfObjects"

  dimensions = {
    BucketName  = aws_s3_bucket.principal.bucket
    StorageType = "AllStorageTypes"
  }

  alarm_actions = [
    aws_sns_topic.alertas.arn
  ]

  tags = {
    Name        = "grupo7-alarma-objetos-s3"
    Environment = var.environment
    Project     = "BackupSync"
    Group       = "7"
  }
}
