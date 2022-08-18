# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Create a new SSH key
resource "hcloud_ssh_key" "hetzner-jenkins-ssh-key" {
  name = "hetzner-jenkins-ssh-key"
  public_key = file(var.ssh_key)
}

# Create a server
resource "hcloud_server" "jenkins" {
  count = var.number_of_servers
  name = "ubuntu-jenkins-${count.index}"
  image = "ubuntu-20.04"
  server_type = "cx31"
  location = "nbg1"
  ssh_keys = [
    "hetzner-jenkins-ssh-key"
  ]

  depends_on = [
    hcloud_ssh_key.hetzner-jenkins-ssh-key
  ]
}

resource null_resource "local-ssh-setup" {
  count = length(hcloud_server.jenkins)
  provisioner "local-exec" {
    command = "sleep 20; ssh-keygen -R ${hcloud_server.jenkins[count.index].ipv4_address}; ssh-keyscan -t rsa -H ${hcloud_server.jenkins[count.index].ipv4_address} >> ~/.ssh/known_hosts"
  }

  depends_on = [
    hcloud_server.jenkins
  ]

}

output "public_ip_addresses" {
  value = "${hcloud_server.jenkins[*].ipv4_address}"
}
