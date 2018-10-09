variable "public_key_path" {
  description = <<EOF
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.pub
EOF
default     = "./testkey.pub"
}

variable "private_key_file" {
  description = "Private key for SSH"
  default     = "./testkey.pem"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default     = "testkey"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

# RHEL 7.5 AMI
variable "aws_amis" {
  default = {
    us-east-1 = "ami-6871a115"
  }
}
