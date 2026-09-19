variable "instance_count" {
  type        = number
  description = "Количество инстансов"
  default     = 5
}

variable "cores" {
  type        = number
  default     = 2
}

variable "memory" {
  type        = number
  default     = 2
}

variable "size" {
  type        = number
  default     = 20
}

variable "key" {
  type    = string
  default = "~/.ssh/ssh-key-1789658954721.pub"
}
