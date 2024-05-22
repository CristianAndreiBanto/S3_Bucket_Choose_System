variable "lambda_role_name" {
  default = "lambda_s3_role"
}

variable "lambda_function_name" {
  default = "s3-file-mover"
}

variable "source_bucket" {
  default = "source-uploads-bucket"
}

variable "small_bucket" {
  default = "small-uploads"
}

variable "medium_bucket" {
  default = "medium-uploads"
}

variable "large_bucket" {
  default = "large-uploads"
}