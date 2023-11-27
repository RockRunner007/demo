provider "aws" {
  default_tags {
    tags = {
      Environment = "test"
    }
  }
}
