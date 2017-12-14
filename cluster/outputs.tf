output "elb_bns_name" {
  value = "${aws_elb.example.dns_name}"
}
