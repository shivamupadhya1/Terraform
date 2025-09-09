variable "region" {
  default = "us-east-1"
}
variable "cidr_range" {
  default = "10.0.0.0/16"
}

variable "cidr_pub_sn" {
  default = "10.0.1.0/24"
}

variable "cidr_pvt_sn" {
  default = "10.0.2.0/24"
}
variable "az_pvt" {
    type = string
  default = "us-east-1a"
}

variable "az_pub" {
    type = string
  default = "us-east-1b"
}

variable "my_ip" {
  type = string
  default = "0.0.0.0/0"
}

variable "ami_id" {
  default = "ami-00ca32bbc84273381"
}