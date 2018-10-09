output "address" {
  value = "${aws_elb.netbackup.dns_name}"
}

output "VM Public address" {
  value = "${aws_instance.netbackup.public_ip}"
}
