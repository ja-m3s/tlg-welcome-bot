# Specify the provider
provider "aws" {
  region = "eu-west-2" # Change to your desired region
}

resource "tls_private_key" "tlg_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "tlg_deployer_key"
  public_key = tls_private_key.tlg_private_key.public_key_openssh

  tags = {
    Name = "discord-welcome-bot"
  }
}

# Create a security group
resource "aws_security_group" "allow_ssh_https" {
  name        = "allow_ssh_https"
  description = "Allow SSH and HTTPS inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to restrict access
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to restrict access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "discord-welcome-bot"
  }
}

# Create an EC2 instance
resource "aws_instance" "discord-welcome-bot" {
  ami             = "ami-0efc5833b9d584374"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.deployer_key.key_name  # Corrected reference
  security_groups = [aws_security_group.allow_ssh_https.name]
  user_data       = file("user-data.sh")  # Corrected syntax
  tags = {
    Name = "discord-welcome-bot"
  }
}

resource "null_resource" "upload_file" {
  provisioner "file" {
    source      = "../bot/config.json"  # Local file path
    destination = "/home/admin/config.json"  # Destination path on the server

    connection {
      type        = "ssh"
      host        = aws_instance.discord-welcome-bot.public_ip
      user        = "admin"  # Change to your server's user
      private_key = tls_private_key.tlg_private_key.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'File uploaded successfully!'"
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.discord-welcome-bot.public_ip
      user        = "admin"  # Change to your server's user
      private_key = tls_private_key.tlg_private_key.private_key_pem
    }
  }

  depends_on = [aws_instance.discord-welcome-bot]
}


# Output the private key
output "private_key" {
  value     = tls_private_key.tlg_private_key.private_key_pem
  sensitive = true  # Mark as sensitive to avoid showing in plain text
}

# Output the public key
output "public_key" {
  value = tls_private_key.tlg_private_key.public_key_pem
}

# Output the key pair name
output "key_pair_name" {
  value = aws_key_pair.deployer_key.key_name
}

# Output the public key to a file
resource "local_file" "public_key_file" {
  filename = "${path.module}/public_key.pub"  # Change the path as needed
  content  = tls_private_key.tlg_private_key.public_key_openssh
  file_permission = "0700"
}

# Output the private key to a file
resource "local_file" "private_key_file" {
  filename = "${path.module}/private_key.pem"  # Change the path as needed
  content  = tls_private_key.tlg_private_key.private_key_pem
  file_permission = "0700"
}

output "instance_public_ip" {
  value = aws_instance.discord-welcome-bot.public_ip
}

# Create a connect.sh file with the SSH command
resource "local_file" "connect_script" {
  filename = "${path.module}/connect.sh"  # Change the path as needed
  content  = <<-EOT
    #!/bin/bash
    ssh -i ${path.module}/private_key.pem admin@${aws_instance.discord-welcome-bot.public_ip}
  EOT
  # Make the script executable
  file_permission = "0755"
}
