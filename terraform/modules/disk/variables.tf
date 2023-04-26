# variable "extra_disk_name" {
#   type = string
#   description = "Extra disk name"
#   default = "jenkins-data"
# }

variable "extra_disk_type" {
  type = string
  description = "Extra disk type"
  default = "pd-ssd"
}

variable "extra_disk_size" {
  description = "Extra disk size"
  default = 20
}