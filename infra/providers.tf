provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "static-site"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}
