provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "my_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Create an ECR repository
resource "aws_ecr_repository" "my_ecr_repo" {
  name = "my-ecr-repo"
}

# Create an ECS cluster
resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = "my-ecs-cluster"
}

# Create a Jenkins server
resource "aws_instance" "jenkins_server" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name = "my-keypair"
  subnet_id = aws_subnet.my_subnet.id
  vpc_security_group_ids = ["sg-123456"]
  
  # Bootstrap script to install Jenkins
  user_data = <<EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install java-1.8.0-openjdk-devel -y
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              sudo yum install jenkins -y
              sudo systemctl start jenkins
              EOF
  
  tags = {
    Name = "jenkins-server"
  }
}
