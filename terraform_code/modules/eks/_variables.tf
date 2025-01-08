variable "sg_ids" {
  type = string
}

variable "subnet_ids" {
  type = list(any)
}

variable "vpc_id" {
  //default = "vpc-5f680722"
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type = string
}
