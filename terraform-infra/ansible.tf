locals {
  ssh_user        = "ubuntu"
  ssh_private_key = "~/.ssh/ssh-key-1789658954721"
}

resource "local_file" "ansible_host_vars" {
  count = length(yandex_compute_instance.server)
  filename = "${path.module}/../host_vars/${yandex_compute_instance.server[count.index].name}.yml"
  directory_permission = "0755"
  file_permission      = "0644"
  content  = <<-EOT
ansible_host: "${yandex_compute_instance.server[count.index].network_interface.0.nat_ip_address}"
ansible_user: "${local.ssh_user}"
ansible_ssh_private_key_file: "${local.ssh_private_key}"
EOT
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  directory_permission = "0755"
  file_permission      = "0644"
  content  = templatefile("${path.module}/inventory.ini.tftpl", {
    hosts = yandex_compute_instance.server[*].name
  })
  depends_on = [local_file.ansible_host_vars]
}
