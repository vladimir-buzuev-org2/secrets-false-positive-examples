variable "aws-account-number" {
  type    = string
  default = "711129375688"
}

variable "role-prefix" {
  type    = string
  default = "strawb-tfc-"
}


variable "tag_names" {
  default = [
    "creds:doormat-aws",
    "aws-account:se_demos_dev",
  ]
}

variable "tf_organization" {
  type    = string
  default = "hashi_strawb_demo"
}
