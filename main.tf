

resource "aws_s3_bucket" "state_bucket" {
  count = length(var.bucket_name)
  bucket = var.bucket_name[count.index]
}

resource "aws_s3_bucket_acl" "example" {
  count = length(var.bucket_name)
  bucket = aws_s3_bucket.state_bucket[count.index].id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  count = length(var.bucket_name)
  bucket = aws_s3_bucket.state_bucket[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

#to pass output to resource when using count
#we duplicate the count in each resource
#we also pass the count.index

#we have terraform.tfvars file when we dont wanna pass extra flag to pick up tfvar file
#for this project we also created a branch cos we many on the project
#git checkout -b name of branch