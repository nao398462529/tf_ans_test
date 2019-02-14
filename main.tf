variable "do_api_token" {}
variable "ssh_fingerprint" {}

provider "digitalocean" {
  token = "${var.do_api_token}"
}

resource "digitalocean_tag" "docker" {
  name = "docker"
}

resource "digitalocean_domain" "njo" {
  name = "njo.space"
}

resource "digitalocean_record" "njo" {
  name    = "test"
  type    = "A"
  domain  = "${digitalocean_domain.njo.name}"
  value   = "${digitalocean_droplet.test_server.ipv4_address}"
}

resource "digitalocean_droplet" "test_server" {

  name                = "test-server"
  image               = "debian-9-x64"
  region              = "tor1"
  size                = "s-1vcpu-1gb"
  tags                = ["${digitalocean_tag.docker.name}"]
  user_data           = "${file("user-data.yml")}"
  ssh_keys            = ["${var.ssh_fingerprint}"]

  lifecycle {
    ignore_changes = ["user_data"]
  }
}

resource "digitalocean_firewall" "webserver" {
  name = "webserver-firewall"
  droplet_ids = ["${digitalocean_droplet.test_server.id}"]

  inbound_rule = [
    {
      protocol = "tcp"
      port_range = "22"
    },
    {
      protocol = "tcp"
      port_range = "80"
    },
    {
      protocol = "tcp"
      port_range = "443"
    },
  ]

  outbound_rule = [
    {
      protocol = "tcp"
      port_range = "53"
    },
    {
      protocol = "udp"
      port_range = "53"
    },
  ]
}

output "node_ips" {
  value = "${digitalocean_droplet.test_server.ipv4_address}"
}
