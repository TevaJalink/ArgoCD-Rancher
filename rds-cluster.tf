resource "aws_db_subnet_group" "db_subnet_group" {
  name       = var.db_subnet_group_name
  subnet_ids = var.vpc_private_subnets

  tags = {
    Name = "DB Subnet Group"
  }
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "rds_monitoring_attachment" {
  name       = "rds-monitoring-attachment"
  roles      = [aws_iam_role.rds_monitoring_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_security_group" "rds_sg" {
  name        = "RDS-SG"
  description = "Security group for RDS instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.vpc_private_subnets
  }
}

resource "aws_kms_key" "rds_kms_key" {
  description             = "KMS Key for RDS Encryption"
  deletion_window_in_days = 7

  tags = {
    Name = var.kms_key_name
  }
}

resource "random_password" "db_user_password" {
  length  = 16
  special = false
  numeric = true
  upper   = true
  lower   = true
}

resource "aws_db_instance" "RDS-Instance" {
  allocated_storage                   = 10
  db_name                             = var.db_name
  engine                              = var.rds_engine
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  identifier                          = var.rds_identifier
  username                            = var.db_username
  password                            = random_password.db_user_password.result
  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name

  # Backup and maintenance configuration
  backup_retention_period   = 7
  backup_window             = var.db_backup_windows
  maintenance_window        = var.db_maintenance_windows
  skip_final_snapshot       = false
  final_snapshot_identifier = var.snapshot_identifier

  # Monitoring configuration
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring_role.arn
  performance_insights_enabled = true

  #encryption configuration
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_kms_key.arn

  multi_az = true
}

resource "aws_db_instance" "RDS-Instance-Replica" {
  replicate_source_db                 = aws_db_instance.RDS-Instance.identifier
  instance_class                      = var.instance_class
  vpc_security_group_ids              = [aws_security_group.rds_sg.id]
  iam_database_authentication_enabled = true

  # Backup and maintenance configuration
  backup_retention_period = 7
  backup_window           = var.db_backup_windows
  maintenance_window      = var.replica_maintenance_windows
  skip_final_snapshot     = true

  # Monitoring configuration
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring_role.arn
  performance_insights_enabled = true

  #encryption configuration
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_kms_key.arn
}