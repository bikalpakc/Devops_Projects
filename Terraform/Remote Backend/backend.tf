terraform {
  backend "s3" {
    bucket = "aws-bucket-for-terraform-remote-backend-practice"
    key    = "terraform-state-file"
    region = "us-east-1"
  }
}
