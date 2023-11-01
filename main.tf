resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "myfirst_vpc"
  }
}   

resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a" 
  tags = {
    Env  = "prod"
    Name = "mypublic-us-east-1a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1b" 
  tags = {
    Env  = "prod"
    Name = "mypublic-us-east-1b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1a" 
  tags = {
    Env  = "prod"
    Name = "myprivate-us-east-1a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1b" 
  tags = {
    Env  = "prod"
    Name = "myprivate-us-east-1b"
  }
}


# Create an internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-igw"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my-rtb-public"
  }
}

# Create custom route tables for the private subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-rtb-private"
  }
}

# Associate the public subnet with the route table
resource "aws_route_table_association" "public_subnet_association1" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association2" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate the private subnets with their respective custom route tables
resource "aws_route_table_association" "private_subnet_association1" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_association2" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_route_table.id
}

#Create main route table 
resource "aws_main_route_table_association" "default" {
  route_table_id = aws_route_table.public_route_table.id
  vpc_id         = aws_vpc.my_vpc.id
}

# Create an EIP for the NAT gateway
#resource "aws_eip" "nat_eip" {
#  vpc      = true

#  tags = {
#    Name = "NATEIP"
#  }
#}

#  Create a NAT gateway
#resource "aws_nat_gateway" "my_nat_gateway" {
#  allocation_id = aws_eip.nat_eip.id
# subnet_ids     = [aws_subnet.public_a.id , aws_subnet.public_b.id]

#  tags = {
#    Name = "my-nat-public1-us-east-1a"
#  }
#}






# gateway attached
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

#resource "aws_route" "private_nat_gateway" {
#  route_table_id         = aws_route_table.private_route_table.id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id
#}

#security group for whitelist ip
resource "aws_security_group" "example_sg" {
  name        = "example-sg"
  description = "Example Security Group"
  vpc_id      = aws_vpc.my_vpc.id # Replace with your VPC ID

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["99.81.126.126/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["13.58.7.144/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["13.236.234.230/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["3.212.17.174/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["3.24.26.71/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["34.249.107.178/32"]
  }
}




#load balancer
resource "aws_lb" "this" {
  name            = "my-alb"
  #security_groups = [aws_security_group.this.id]
  subnets  = [aws_subnet.public_a.id,aws_subnet.public_b.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This ALB is live now."
      status_code  = "200"
    }
  }
}

resource "aws_lb_target_group" "this" {
  name_prefix = "my-alb"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = ["/WeatherForecast*"]
    }
  }
}


#ecr
resource "aws_ecr_repository" "my_ecr_repository" {
    name = "my-ecr-repo"
}


#ecs
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}

#iam role for ecs
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

#task definition
resource "aws_ecs_task_definition" "my_app" {
  family                   = "my-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu    = "256"
  memory = "512"

  container_definitions = jsonencode([{
    name  = "my-app-container"
    image = "your-ecr-image-uri:latest" # Replace with your ECR image URI
    
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

#service
resource "aws_ecs_service" "my_app_service" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_app.arn
  launch_type     = "FARGATE"


  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_port   = 80
    container_name   = "my-app-container"
  }


  network_configuration {
    subnets = [aws_subnet.private_a.id, aws_subnet.private_b.id]
   # security_groups = [aws_security_group.ecs_security_group.id]
  }
}

#sqs
resource "aws_sqs_queue" "example" {
  name = "example-queue"
}

resource "aws_iam_role" "rds_sqs_role" {
    name = "rds-sqs-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = {
            Service = "rds.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_policy" "rds_sqs_policy" {
    name = "rds-sqs-policy"

    description = "Policy to allow RDS to publish to SQS"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action = "sqs:SendMessage",
            Effect = "Allow",
            Resource = aws_sqs_queue.example.arn
        }]
    })
}

resource "aws_iam_role_policy_attachment" "rds_sqs_policy_attachment" {
    policy_arn = aws_iam_policy.rds_sqs_policy.arn
    role       = aws_iam_role.rds_sqs_role.name
}


resource "aws_db_subnet_group" "default" {
  name = "my-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
    
  ]

  tags = {
    Env  = "production"
    Name = "my-db-subnet-group"
  }
}

#rds
resource "aws_db_instance" "example" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  identifier           = "example-db" 
  username             = "dbuser"
  password             = "dbpassword"
  parameter_group_name = "default.mysql5.7"
  multi_az             = true 
  db_subnet_group_name = "my-db-subnet-group"
}




