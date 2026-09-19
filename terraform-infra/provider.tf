terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}
provider "yandex" {
  service_account_key_file = "authorized_key.json"
  cloud_id  = "b1gl9hdpdr35i83uh5t5"
  folder_id = "b1gbb5kej5tlskp8i5oq"
  zone      = "ru-central1-a"
}
