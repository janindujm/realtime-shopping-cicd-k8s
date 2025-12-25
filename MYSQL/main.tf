provider "aws" {
  region = "us-east-1"  # change as needed
}

# --------------------
# Security Group
# --------------------
resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Allow MySQL access"
  vpc_id      = "vpc-0be6f3e9e96474654"  # your existing VPC ID

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # open access (use restricted CIDR in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------
# Subnets
# --------------------
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = ["vpc-0be6f3e9e96474654"]
  }
}

# --------------------
# DB Subnet Group
# --------------------
resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-subnet-group"
  subnet_ids = slice(data.aws_subnets.private.ids, 0, 2)  # pick 2 subnets

  tags = {
    Name = "mysql-subnet-group"
  }
}

# --------------------
# MySQL RDS Instance
# --------------------
resource "aws_db_instance" "mysql" {
  identifier              = "my-mysql-db"
  engine                  = "mysql"
  engine_version          = "8.0"        # choose version you need
  instance_class          = "db.t3.micro"
  allocated_storage       = 20           # in GB
  storage_type            = "gp2"
  username                = "admin"      # master username
  password                = "Password123!" # master password (use secrets manager for production)
  db_subnet_group_name    = aws_db_subnet_group.mysql_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.mysql_sg.id]
  publicly_accessible     = true
  skip_final_snapshot     = true

  tags = {
    Name = "my-mysql-db"
  }
}

# --------------------
# Outputs
# --------------------
output "mysql_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "mysql_port" {
  value = aws_db_instance.mysql.port
}
