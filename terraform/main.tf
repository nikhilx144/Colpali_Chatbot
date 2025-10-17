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

# Create an EC2 key pair for SSH access.
# NOTE: You must create the 'deployer-key.pub' public key file yourself.
# Use the command: ssh-keygen -t rsa -b 4096 -f ~/.ssh/deployer-key
resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDS05RiC3iwF5ISZkuPbivKH8IifYyve5TXKPnlKDvpv4hd9+9gCqmCi7Hn40dgNzyfo0URaCVFVBDR9jmelRfgsQQ5qIcqX3Mam9xnmWufMjriji2v+N5qT8FONk4paHj4di3dzrV5Vb1rMUybOU4rIA+mhCezjsbShMtvsVGTOxJTol65UZn5SsrKcBsTgxvzAmEnm95hVOcFvz4QooxNwAFMjkFMaq0/9HpOFbvBjsDuDp7QH4eDgLTnINAfP4PWpeuBtoMXXLdspLw/RskNW/fds3/ivFMlaBLkTiN3MC3mUNMau4iTeCY7BfLtKsIhId1AznyMJXOIDKz+9SxSZl/yKgJwtXqpSXnt75fCIkbXxGacIru0Hd0jAwWx8ZVYF6zYjdY+uZ9epSQCgTGBBV8aXivltvnvUykCPX5zj4tGdJYq0Fgh2YK/BKzSUfQvuzui9uzk8Sc7uzLQ8dkkH1LaherfNx6u2iKETO/vBLiUmha9UXz4914t6+y5z9wNrAwkA825IP0DuFA5ccAGAs0q1vrkNmmIdHhlmhrnrPeW6w6Ifh/UifZWjfU8+0hx8paeRTnCcd/snnVpb8EZIH6F+D5Pc+bKS5wPOy7/GpKR5EK9CMs5zWA6saNxaItZoIEbClLMBSnduVFqx9/uG4+mCo/Lt7+WiXBi28Ua8w== nikhi@Nikhil"
}

# Create the EC2 instance
resource "aws_instance" "web_server" {
  # Amazon Linux 2023 AMI for ap-south-2 (Mumbai) region
  ami           = "ami-047087104d2773d13"
  
  # Use the affordable t3.micro instance type
  instance_type = "t3.micro"

  # Associate the security group and key pair created above
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name

  # User data script to run on instance startup
  # This script installs and starts Docker, and adds ec2-user to the docker group.
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