provider "aws" {
  region = "us-east-1"  # Change your region
}

# Security group for EC2
resource "aws_security_group" "k8s_client_sg" {
  name        = "k8s-client-sg"
  description = "Allow SSH and outbound access to EKS cluster"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_client" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t2.micro"
  security_groups        = [aws_security_group.k8s_client_sg.name]
  key_name               = "devops-project-1"

  user_data = <<-EOT
              #!/bin/bash
              # Update packages
              yum update -y

              # Install dependencies
              yum install -y curl unzip tar jq

              sudo rpm --import https://yum.corretto.aws/corretto.key
              sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
              sudo yum install -y java-17-amazon-corretto-devel

              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              rm -rf awscliv2.zip aws/

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

              chmod +x kubectl
              mv kubectl /usr/local/bin/

              ### Update kubeconfig for EKS
              ### aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster

              sudo amazon-linux-extras enable docker
              sudo yum install docker -y

              # Install Kafka client (binary)
  
              curl -LO "https://dlcdn.apache.org/kafka/4.1.1/kafka_2.13-4.1.1.tgz"
              tar -xzf kafka_2.13-4.1.1.tgz 
              mv kafka_2.13-4.1.1 /opt/kafka
              echo 'export PATH=$PATH:/opt/kafka/bin' >>  ~/.bashrc
              source ~/.bashrc
              sudo yum install bash-completion -y
              source /usr/share/bash-completion/bash_completion   # may vary by distro
              source <(kubectl completion bash)
              
              EOT

  tags = {
    Name = "k8s-client"
  }
}

output "k8s_client_http" {
  value = "http://${aws_instance.k8s_client.public_ip}:8080"
}

output "k8s_client" {
  value = "ssh -i C:/Users/User/Downloads/devops-project-1.pem ec2-user@${aws_instance.k8s_client.public_ip}"
}
