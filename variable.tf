variable "function_name" {
  type        = string
  description = "Lambda function name"
  default     = "access_key_secret_rotation"
}

variable "filename" {
  type        = string
  description = "Zip file name that needs to be uploaded"
  default     = "lambda.zip"
}
