
data "aws_ami" "ami_to_test" {
  owners           = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20221103.3-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "testing_3tier" {
  ami = data.aws_ami.ami_to_test.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet[0].id
  user_data = file("${path.module}/template/frontend.sh")
  vpc_security_group_ids = [aws_security_group.practice_three_tier.id]
  key_name = "keypair-for-peering"


}

resource "aws_security_group" "practice_three_tier" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = local.vpc_id

  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "http"
  }
}