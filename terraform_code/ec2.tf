resource "aws_security_group" "jenkins" {
  name        = "jenkins"
  description = "Jenkins network traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.workstation_ip]
  }

  ingress {
    description = "ALL traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins"
  }
}

resource "aws_security_group" "ansible" {
  name        = "ansible"
  description = "EC2 network traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.workstation_ip]
  }

  ingress {
    description = "ALL traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible"
  }
}

resource "aws_instance" "jenkins" {
  for_each               = toset(["jenkins-master", "build-slave"])
  ami                    = var.amis[var.region]
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]

  associate_public_ip_address = true

  tags = {
    Name = "${each.key}"
  }
}

resource "aws_instance" "ansible" {
  ami                    = var.amis[var.region]
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.ansible.id]

  associate_public_ip_address = true

  #userdata
  user_data = <<EOF
#!/bin/bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
echo -e "${file("extra_files/workshop.pem")}" > /opt/workshop.pem
cat << 'EOT' > /opt/hosts
[jenkins-master]
${aws_instance.jenkins["jenkins-master"].private_ip}
[jenkins-master:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/opt/workshop.pem
[jenkins-slave]
${aws_instance.jenkins["build-slave"].private_ip}
[jenkins-slave:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/opt/workshop.pem
EOT
chmod 400 /opt/workshop.pem
echo finished > /opt/finished
EOF
  tags = {
    Name = "ansible"
  }
}
