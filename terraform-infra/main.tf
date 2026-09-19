data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_vpc_network" "main_network" {
  name = "main-network"
}

resource "yandex_vpc_subnet" "main_subnet" {
  name           = "main-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main_network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "server" {
  count = 5

  name        = "server_${count.index + 1}"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 15
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/ssh-key-1789658954721.pub")}"
  }
}

output "public_ips" {
  description = "Публичные IP адреса созданных серверов"
  value       = yandex_compute_instance.server[*].network_interface.0.nat_ip_address
}
