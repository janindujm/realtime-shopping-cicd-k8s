provider "aws" {
  region = "us-east-1" # change to your region
}

# Security group for MSK cluster
resource "aws_security_group" "msk_sg" {
  name        = "msk-sg"
  description = "Allow PLAINTEXT access to MSK brokers"
  vpc_id      = "vpc-0be6f3e9e96474654"

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # open for unauthenticated access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Subnets (replace with your own private subnets)
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = ["vpc-0be6f3e9e96474654"]
  }
}

# MSK Cluster
resource "aws_msk_cluster" "my_kafka" {
  cluster_name           = "my-kafka-cluster"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    client_subnets  = slice(data.aws_subnets.private.ids, 0, 2)
    security_groups = [aws_security_group.msk_sg.id]
    storage_info {
      ebs_storage_info {
        volume_size = 10
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "PLAINTEXT"
      in_cluster    = false
    }
  }

  tags = {
    Name = "my-kafka-cluster"
  }
}


output "msk_bootstrap_brokers" {
  value = aws_msk_cluster.my_kafka.bootstrap_brokers
}
