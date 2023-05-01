# Define the AWS provider
provider "aws" {
  region = "us-west-2"
}

# Define the VPC and subnets
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "jenkins_subnet_a" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.jenkins_vpc.id
}

resource "aws_subnet" "jenkins_subnet_b" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.jenkins_vpc.id
}

# Define the security group for the Jenkins server
resource "aws_security_group" "jenkins_sg" {
  name_prefix = "jenkins-sg"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

# Define the ECR repository
resource "aws_ecr_repository" "my_repository" {
  name = "my_repository"
}

# Define the ECS cluster
resource "aws_ecs_cluster" "jenkins_cluster" {
  name = "jenkins-cluster"
}

# Define the EC2 instance for the Jenkins server
resource "aws_instance" "jenkins_instance" {
  ami           = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  key_name      = "my_key_pair"
  subnet_id     = aws_subnet.jenkins_subnet_a.id

  user_data = <<-EOF
    #!/bin/bash
    echo "export JENKINS_ECR_REPO=${aws_ecr_repository.my_repository.repository_url}" >> /etc/profile
    echo "export JENKINS_CLUSTER=${aws_ecs_cluster.jenkins_cluster.arn}" >> /etc/profile
    echo "export AWS_REGION=${var.aws_region}" >> /etc/profile
    echo "export AWS_DEFAULT_REGION=${var.aws_region}" >> /etc/profile
    echo "export AWS_ACCESS_KEY_ID=${var.aws_access_key}" >> /etc/profile
    echo "export AWS_SECRET_ACCESS_KEY=${var.aws_secret_key}" >> /etc/profile
    echo "export AWS_DEFAULT_OUTPUT=json" >> /etc/profile

    # Install Docker and Jenkins
    yum update -y
    amazon-linux-extras install docker
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user
    wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
    rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
    yum install -y jenkins
    systemctl enable jenkins
    systemctl start jenkins
  EOF

  tags = {
    Name = "jenkins-instance"
  }

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
}

# Output the Jenkins server public IP address
output "jenkins_server
