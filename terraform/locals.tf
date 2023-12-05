locals {
	name = "${var.env}-${var.name}"
	sshUsername = var.name
	sshKeyFile = pathexpand("../secrets/ssh/id_rsa.pub")
	sshKey = file(local.sshKeyFile)
	zone = "${var.region}-${var.zone}"
}
