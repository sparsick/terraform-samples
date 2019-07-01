variable "hcloud_token" {}
variable "hcloud_ssh_key" {}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = "${var.hcloud_token}"
}

# Create a server
resource "hcloud_server" "gesteak" {
  name = "gesteak"
  image = "ubuntu-18.04"
  server_type = "cx11"
  location = "nbg1"
  ssh_keys = [
    "bbv-provisioning",
    "volkenas@PC10005801.WSL"
  ]

  provisioner "remote-exec" {
   inline = [
     "while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done",
     "apt-get -qq update -y",
     "apt-get -qq install python -y",
   ]

   connection {
     host        = "${self.ipv4_address}"
     type        = "ssh"
     user        = "root"
     private_key = "${file("${var.hcloud_ssh_key}")}"
   }
  }

  provisioner "local-exec" {
    working_dir = "."
    command     = "ssh-keygen -R ${self.ipv4_address}; ssh-keyscan -t rsa -H ${self.ipv4_address} >> ~/.ssh/known_hosts"
  }

  provisioner "local-exec" {
      working_dir = "."
      command     = "ansible-playbook -u root --private-key ${var.hcloud_ssh_key} playbooks/setup-server.yml -i ${self.ipv4_address},"
  }
}

output "public_ip_address" {
  value = "${hcloud_server.demo.ipv4_address}"
}
