resource "aws_db_subnet_group" "default" {
  name       = var.environment_name
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_rds_cluster" "default" {
  count = var.sql_enabled ? 1 : 0

  cluster_identifier = var.environment_name

  engine      = var.sql_engine
  engine_mode = var.sql_engine_mode

  database_name   = var.sql_database_name
  master_username = var.sql_master_username
  master_password = var.sql_master_password

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.node.id]

  storage_encrypted = true

  deletion_protection     = true // Don't Delete Ever! Except manually.
  backup_retention_period = 20

  // enabled_cloudwatch_logs_exports = ["audit", "error", "general"]

  dynamic "scaling_configuration" {
    for_each = var.sql_engine_mode == "serverless" ? [1] : []
    content {
      auto_pause               = true
      min_capacity             = var.sql_serverless_min
      max_capacity             = var.sql_serverless_max
      seconds_until_auto_pause = var.sql_serverless_seconds_until_auto_pause
      timeout_action           = "ForceApplyCapacityChange"
    }
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.sql_engine_mode == "serverless" ? 0 : var.sql_node_count

  engine     = var.sql_engine
  identifier = "${var.environment_name}-${count.index}"

  cluster_identifier = aws_rds_cluster.default.0.id

  instance_class = var.sql_instance_class

  db_subnet_group_name = aws_db_subnet_group.default.name
}

resource "aws_db_instance" "default" {
  count = var.sql_instance_enabled ? 1 : 0

  identifier = var.environment_name

  allocated_storage = 20
  storage_type      = "gp2"
  engine            = var.sql_engine
  engine_version    = var.sql_engine_version
  instance_class    = var.sql_instance_class
  name              = var.sql_database_name
  username          = var.sql_master_username
  password          = var.sql_master_password

  db_subnet_group_name = aws_db_subnet_group.default.name

  storage_encrypted = true

// TODO
    //deletion_protection     = true // Don't Delete Ever! Except manually.
}