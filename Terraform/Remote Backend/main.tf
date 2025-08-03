provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "key-pair" {
  key_name   = "aws_keypair1"                                      # Replace with your desired key name
  public_key = file("C:/Users/Bikalpa/Downloads/aws_keypair1.pub") # Replace with the path to your public key file
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "my_sg" {
  name        = "my-security-group"
  description = "Security group for default VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_instance_1" {
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  key_name               = aws_key_pair.key-pair.key_name

  connection {
    type        = "ssh"
    user        = "ubuntu"                                            # Replace with the appropriate username for your EC2 instance
    private_key = file("C:/Users/Bikalpa/Downloads/aws_keypair1.pem") # Replace with the path to your private key
    host        = self.public_ip
  }

  # File provisioner to copy a file from local to the remote EC2 instance
  provisioner "file" {
    source      = "app.py"              # Replace with the path to your local file
    destination = "/home/ubuntu/app.py" # Replace with the path on the remote instance
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello Bikalpa from the remote instance'",
      "sudo apt update -y",                  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip", # Example package installation
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }
}
