variable "environment" {
  description = "The target environment (main, dev)"
  type        = string
}

variable "clusters" {
  type = map(object({
    name         = string
    image        = string
    cpu_limit    = string
    memory_limit = string
  }))
  default = {
    "bannote-main-prod" = {
      name         = "bannote-main-prod"
      image        = "ubuntu:22.04"
      cpu_limit    = "4"
      memory_limit = "8GB"
    }
    "bannote-main-stg" = {
      name         = "bannote-main-stg"
      image        = "ubuntu:22.04"
      cpu_limit    = "2"
      memory_limit = "4GB"
    }
    "bannote-main-dev" = {
      name         = "bannote-main-dev"
      image        = "ubuntu:22.04"
      cpu_limit    = "2"
      memory_limit = "4GB"
    }
    "bannote-dev-prod" = {
      name         = "bannote-dev-prod"
      image        = "ubuntu:22.04"
      cpu_limit    = "1"
      memory_limit = "2GB"
    }
    "bannote-dev-stg" = {
      name         = "bannote-dev-stg"
      image        = "ubuntu:22.04"
      cpu_limit    = "1"
      memory_limit = "2GB"
    }
    "bannote-dev-dev" = {
      name         = "bannote-dev-dev"
      image        = "ubuntu:22.04"
      cpu_limit    = "1"
      memory_limit = "2GB"
    }
  }
}