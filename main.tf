#Main VPC
resource "aws_vpc" "main" {
cidr_block = "10.0.0.0/16"
instance_tenancy = "default"
enable_dns_hostnames = true

tags = {
Name = "Main VPC"
}
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = "true"
tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
tags = {
    Name = "Private Subnet"
  }
}

resource "aws_internet_gateway" "gateway" {
       vpc_id = aws_vpc.main.id
tags = {
    Name = "Main Internet Gateway"
  }
}

resource "aws_eip" "nat_eip" {
	vpc = true
	depends_on = [aws_internet_gateway.gateway]
	tags = {
	Name = "NAT Gateway EIP"
	}
}

resource "aws_nat_gateway" "nat" {
	allocation_id = aws_eip.nat_eip.id
	subnet_id = aws_subnet.public.id
	tags = {
	Name = "Main NAT Gateway"
	}
}

resource "aws_route_table" "public" {
      vpc_id = aws_vpc.main.id
           route {
              cidr_block = "0.0.0.0/0"
              gateway_id = aws_internet_gateway.gateway.id
          }
tags = {
                 Name = "Public Route Table"
          }
       }


resource "aws_route_table_association" "public"{
   subnet_id   = aws_subnet.public.id
   route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
      vpc_id = aws_vpc.main.id
           route {
              cidr_block = "0.0.0.0/0" 
              gateway_id = aws_internet_gateway.gateway.id
          }
tags = {
                 Name = "Private Route Table"
          }
       }


resource "aws_route_table_association" "private"{
   subnet_id   = aws_subnet.private.id
   route_table_id = aws_route_table.private.id
}

# SECURITY GROUPS


#Public security groups
resource "aws_security_group" "security-group-public" {
  name        = "security-group-public"
  vpc_id      = "default"

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  tags = {
    Name = "security-group-public"
  }
}

#Private security groups

resource "aws_security_group" "security-group-private" {
  name        = "security-group-private"
  vpc_id      = "default"

  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

   tags = {
    Name = "security-group-private"
  }
}

# EC2 INSTANCE

resource "aws_instance" "instance-public" {
   ami = "ami-0ac43988dfd31ab9a"
   instance_type = "t2.micro"
   associate_public_ip_address = true
   subnet_id = aws_subnet.public.id
   vpc_security_group_ids = [aws_security_group.security-group-private.id]
tags = { 
         Name = "instance-public"
     }
}

# S3 BUCKET

resource "aws_s3_bucket" "private-bucket" {
  bucket = "private-bucket"
  acl = "private"
}

resource "aws_kinesis_stream" "kinesis-stream" {
  name             = "kinesis-stream"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = []
}

resource "aws_glue_catalog_database" "glue_database" {
  name = "gluedatabasetwitter"
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = "gluetabletwitter"
  database_name = "gluedatabasetwitter"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location = "s3://private-bucket/event-streams/my-stream"
    input_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name = "kinesis-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    parameters = {
      "serialization.format" = 1
    }
  }
}


resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name        = "firehose-delivery-stream"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis-stream.arn
    role_arn = aws_iam_role.firehose_role.arn
  }
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.private-bucket.arn

    processing_configuration {
      enabled = "true"

      }
    }
  }


resource "aws_iam_role" "firehose_role" {
  name = "firehose_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_athena_database" "athenadb" {
  name   = "athenadb"
  bucket = aws_s3_bucket.private-bucket.bucket
}