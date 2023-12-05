data "google_compute_network" "dpsrv" {
  name = "default"
}

resource "google_compute_address" "dpsrv" {
  name         = local.name
  address_type = "EXTERNAL"
}

resource "google_compute_disk" "dpsrv" {
  name = "${local.name}-data"
  type = "pd-ssd"
  zone = local.zone
  size = 2

  physical_block_size_bytes = 4096
}

resource "google_compute_instance" "dpsrv" {
  name                      = local.name
  machine_type              = "n1-standard-1"
  zone                      = local.zone
  can_ip_forward            = false
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = data.google_compute_network.dpsrv.name
    access_config {
      nat_ip = google_compute_address.dpsrv.address
    }
  }

  tags = ["http-server","https-server"]

  metadata = {
    ssh-keys = "${local.sshUsername}:${local.sshKey}"
  }

  metadata_startup_script = <<EOF
#!/bin/bash -ex

/sbin/iptables -A INPUT -p udp --dport 53 -j ACCEPT
/sbin/iptables -A INPUT -p tcp --dport 53 -j ACCEPT
/sbin/iptables -A INPUT -p tcp --dport 80 -j ACCEPT
/sbin/iptables -A INPUT -p tcp --dport 443 -j ACCEPT

[ -d /mnt/disks/data ] || mkdir /mnt/disks/data

if ! blkid /dev/sdb; then
	echo "Formatting new disk"
	mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb && mount -o discard,defaults /dev/sdb /mnt/disks/data
	mount -o discard,defaults /dev/sdb /mnt/disks/data
	chown -R dpsrv:dpsrv /mnt/disks/data
fi

if ! grep -qs '/mnt/disks/data ' /proc/mounts; then
	echo "Mounting disk"
	mount -o discard,defaults /dev/sdb /mnt/disks/data
fi

EOF

  lifecycle {
    ignore_changes = [attached_disk]
  }
}

resource "google_compute_attached_disk" "dpsrv" {
  disk     = google_compute_disk.dpsrv.id
  instance = google_compute_instance.dpsrv.id
}

resource "google_compute_firewall" "dpsrv" {
  name    = local.name
  network = data.google_compute_network.dpsrv.name

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  allow {
    protocol = "tcp"
    ports    = ["53", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

