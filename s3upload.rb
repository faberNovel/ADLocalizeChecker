#!/usr/bin/env ruby

require 'aws-sdk-s3'

version = ARGV[0]
file_path = ARGV[1]
username = ARGV[2]
secret = ARGV[3]
s3 = Aws::S3::Resource.new(
  credentials: Aws::Credentials.new(username, secret),
  region: "eu-west-3"
)
obj = s3.bucket('ad-localize-checker').object('download/' + version + '/' + File.basename(file_path))
obj.upload_file(file_path, { acl: 'public-read' })
puts "Uploaded to " + obj.public_url
