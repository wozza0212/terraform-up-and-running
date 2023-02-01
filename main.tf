provider "aws" {
    region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
    ami             = "ami-0fb653ca2d3203ac1"
    instance_type   = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World.. I am waking up" > index.html
                nohup busybox httpd -f -p ${var.server_port} & 
                EOF

    lifecycle {
        create_before_destroy = true
    }

    user_data_replace_on_change = true

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration    = aws_launch_configuration.example.name
    vpc_zone_identifier     = data.aws_subnets.default.ids

    min_size = 2
    max_size = 10

    tag {
        key                 = "Name"
        value               = "terraform-asg-example"
        propogate_at_launch = true 
    }
}

variable "server_port" {
    description = "The port the server will use for HTTP requests!"
    type        = number
    default     = 8080
}

output "public_ip" {
    value       = aws_instance.example.public_ip
    description = "The public IP address of the webserver"
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
        name        = "vpc-id"
        values      = [data.aws_vpc.default.id]
    }
    
}