variable "domain_name" {
  description = "The domain name for the site (e.g., example.com)"
  type        = string
}

variable "subdomain" {
  description = "The subdomain to serve the site from"
  type        = string
  default     = "www"
}

variable "to_email" {
  description = "Email address to receive contact form submissions"
  type        = string
}

variable "from_email" {
  description = "Email address to send contact form submissions from (must be SES-verified)"
  type        = string
}

variable "enable_recaptcha" {
  description = "Enable reCAPTCHA verification for contact form"
  type        = bool
  default     = true
}

variable "recaptcha_site_key" {
  description = "reCAPTCHA site key for frontend"
  type        = string
  default     = ""
}

variable "recaptcha_secret_key" {
  description = "reCAPTCHA secret key for backend verification"
  type        = string
  default     = ""
  sensitive   = true
}
