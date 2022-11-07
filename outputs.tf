output "public_ip" {
  value = aws_instance.ubuntu.*.public_ip
}

#output "private_key_pem" {
#  value = tls_private_key.awskey.*.private_key_pem
#  sensitive = true
#}
