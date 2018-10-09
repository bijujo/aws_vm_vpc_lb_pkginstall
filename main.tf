# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "sharedvpc" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "Netbackup_VPC"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.sharedvpc.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.sharedvpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "netbackup" {
  vpc_id                  = "${aws_vpc.sharedvpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# A security group for Netbackup
resource "aws_security_group" "netbackup" {
  name        = "terraform_example_netbackup"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.sharedvpc.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "netbackup" {
  name = "terraform-example-elb"

  subnets         = ["${aws_subnet.netbackup.id}"]
  security_groups = ["${aws_security_group.netbackup.id}"]
  instances       = ["${aws_instance.netbackup.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "netbackup" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    private_key = "${file(var.private_key_file)}"
    timeout = "2m"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.netbackup.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.netbackup.id}"

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install httpd and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      #"sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo service httpd start",
    ]
  }
  tags {
    Name = "Netbackup_Master_Server"
  }
}
