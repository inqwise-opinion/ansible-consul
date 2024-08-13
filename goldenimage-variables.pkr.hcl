variable "base_path" {
    type = string
    default = "s3://bootstrap-opinion-stg/playbooks"
}

variable "tag" {
  type    = string
  default = "latest"
}

variable "app" {
  type    = string
  default = "consul"
}

variable "region" {
  type    = string
  default = "il-central-1"
}

variable "extra" {
  default = {
    private_domain = "opinion-stg.local"
  }
}

variable "aws_profile" {
  default = "opinion-stg"
}