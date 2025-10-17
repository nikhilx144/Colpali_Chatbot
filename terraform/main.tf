# -----------------------------------------------------------------------------
# IAM ROLE FOR EC2 TO ACCESS ECR
# This gives the EC2 instance permissions to pull images from the ECR repository.
# -----------------------------------------------------------------------------

# 1. Create an IAM Role that the EC2 service can assume
resource "aws_iam_role" "ec2_ecr_role" {
  name = "ec2-ecr-access-role"

  # Policy that allows EC2 to assume this role
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# 2. Attach the AWS-managed policy that grants read-only access to ECR
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 3. Create an instance profile to act as a container for the role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ecr-access-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

# -----------------------------------------------------------------------------
# NETWORKING AND SECURITY
# -----------------------------------------------------------------------------

# Create a security group to control traffic to the EC2 instance
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH inbound traffic"

  # Allow incoming SSH traffic from any IP address
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming HTTP traffic from any IP address
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebServerSG"
  }
}

# -----------------------------------------------------------------------------
# EC2 INSTANCE CONFIGURATION
# -----------------------------------------------------------------------------

# Create an EC2 key pair for SSH access.
# NOTE: This requires you to have a public key file named 'deployer-key.pub'
# in your local machine's ~/.ssh/ directory.
resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/deployer-key.pub")
}

# Create the EC2 instance
resource "aws_instance" "web_server" {
  # Amazon Linux 2023 AMI for ap-south-2 (Mumbai) region
  ami           = "ami-047087104d2773d13"
  
  # Use the affordable t3.micro instance type
  instance_type = "t3.micro"

  # Associate the IAM instance profile created above
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Associate the security group and key pair
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name

  # User data script to run on instance startup to install Docker
  user_data = <<-EOT
    #!/bin/bash
    sudo dnf update -y
    sudo dnf install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
  EOT

  tags = {
    Name = "OpenAI-Chatbot-Server"
  }
}