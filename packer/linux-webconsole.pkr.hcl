# Use like:
#  $ PACKER_LOG=1 packer build --on-error=ask -var-file=<something>.pkrvars.hcl openstack.pkr.hcl

# "timestamp" template function replacement:s
locals { timestamp = formatdate("YYMMDD-hhmm", timestamp())}

variable "source_image_name" {
  type = string
}

variable "network" {
  type = string
}

variable "floating_ip_network" {
  type = string
}

variable "flavor" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "volume_size" {
  type = number
  default = 5
}

variable "disk_format" {
  type = string
  default = "qcow2"
}

variable "distro_name" {
  type = string
}

variable "ssh_username" {
  type = string
}

source "openstack" "linux-webconsole" {
  image_name = "${var.distro_name}-webconsole-${local.timestamp}"
  image_visibility = "private"
  image_disk_format = "${var.disk_format}"

  source_image_name = "${var.source_image_name}"
  flavor = "${var.flavor}"
  networks = ["${var.network}"]
  security_groups = "${var.security_groups}"
  floating_ip_network = "${var.floating_ip_network}"

  use_blockstorage_volume = true
  volume_size = "${var.volume_size}"

  communicator = "ssh"
  ssh_username = "${var.ssh_username}"
  ssh_clear_authorized_keys = true
}

build {
  source "source.openstack.linux-webconsole" { }

  provisioner "ansible" {
    galaxy_file = "${path.root}/../requirements.yml"
    playbook_file = "${path.root}/../ansible/linux-webconsole.yml"
    use_proxy = false
    extra_arguments = ["-v"]
  }

  post-processor "manifest" {
    custom_data = {
      source = "${source.name}"
    }
  }
}
