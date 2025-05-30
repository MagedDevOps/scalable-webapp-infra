resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "scalable-web-app-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = "${var.aws_region}${element(tolist(["a", "b"]), count.index)}" # Assuming AZs a and b
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-az${element(tolist(["a", "b"]), count.index)}"
  }
}

# Private Application Subnets
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_app_subnet_cidrs, count.index)
  availability_zone = "${var.aws_region}${element(tolist(["a", "b"]), count.index)}"

  tags = {
    Name = "private-app-subnet-az${element(tolist(["a", "b"]), count.index)}"
  }
}

# Private Database Subnets
resource "aws_subnet" "private_db" {
  count             = length(var.private_db_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_db_subnet_cidrs, count.index)
  availability_zone = "${var.aws_region}${element(tolist(["a", "b"]), count.index)}"

  tags = {
    Name = "private-db-subnet-az${element(tolist(["a", "b"]), count.index)}"
  }
}

# Private Web Subnets
resource "aws_subnet" "private_web" {
  count             = length(var.private_web_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_web_subnet_cidrs, count.index)
  availability_zone = "${var.aws_region}${element(tolist(["a", "b"]), count.index)}"

  tags = {
    Name = "private-web-subnet-az${element(tolist(["a", "b"]), count.index)}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "scalable-web-app-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Private Route Table (for Private App and Web tiers - assuming no NAT Gateway for now)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route-table"
  }
}

# Associate Private Route Table with Private App Subnets
resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = element(aws_subnet.private_app.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

# Associate Private Route Table with Private Web Subnets
resource "aws_route_table_association" "private_web" {
  count          = length(aws_subnet.private_web)
  subnet_id      = element(aws_subnet.private_web.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

# Security Groups

# ALB Security Group (Internet-facing)
resource "aws_security_group" "alb" {
  name_prefix = "scalable-webapp-alb-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "scalable-webapp-alb-sg"
  }
}

# Internal ALB Security Group
resource "aws_security_group" "internal_alb" {
  name_prefix = "scalable-webapp-internal-alb-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow from entire VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "scalable-webapp-internal-alb-sg"
  }
}

# Application Tier Security Group
resource "aws_security_group" "app_tier" {
  name_prefix = "scalable-webapp-app-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]  # Allow traffic from Internet-facing ALB
  }

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow from entire VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "scalable-webapp-app-sg"
  }
}

# Web Tier Security Group
resource "aws_security_group" "web_tier" {
  name_prefix = "scalable-webapp-web-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.web_port # Assuming web server runs on a standard web port (e.g., 80 or 443)
    to_port     = var.web_port
    protocol    = "tcp"
    security_groups = [aws_security_group.app_tier.id] # Allow traffic from Application Tier SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "scalable-webapp-web-sg"
  }
}

# Database Security Group
resource "aws_security_group" "db_tier" {
  name_prefix = "scalable-webapp-db-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.db_port # Standard DB port (e.g., 3306 for MySQL)
    to_port     = var.db_port
    protocol    = "tcp"
    security_groups = [aws_security_group.app_tier.id] # Allow traffic from Application Tier SG
  }

  tags = {
    Name = "scalable-webapp-db-sg"
  }
}

# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  name_prefix = "scalable-webapp-bastion-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22 # SSH port
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.office_ip_cidr] # Using the variable instead of hardcoded value
  }

  egress {
    from_port   = 22 # SSH port
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.app_tier.id, aws_security_group.web_tier.id] # Allow SSH to app and web tiers
  }

  tags = {
    Name = "scalable-webapp-bastion-sg"
  }
}

# Internet-facing Application Load Balancer
resource "aws_lb" "internet_facing" {
  name               = "scalable-webapp-alb-internet"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public.*.id

  tags = {
    Name = "scalable-webapp-alb-internet"
  }
}

# Internet-facing ALB HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internet_facing.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tier.arn # Forward to Application Tier
  }
}

# Internet-facing ALB HTTPS Listener (Optional - requires certificate)
/*
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.internet_facing.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn # Define this variable if using HTTPS

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tier.arn
  }
}
*/

# Internal Application Load Balancer
resource "aws_lb" "internal" {
  name               = "scalable-webapp-alb-internal"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_tier.id] # Allow traffic from App Tier
  subnets            = aws_subnet.private_app.*.id # Located in private app subnets

  tags = {
    Name = "scalable-webapp-alb-internal"
  }
}

# Internal ALB HTTP Listener (or appropriate protocol/port for app to web communication)
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = var.app_port # Listen on the application port
  protocol          = "HTTP" # Or appropriate protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tier.arn # Forward to Web Tier
  }
}

# Target Group for Application Tier
resource "aws_lb_target_group" "app_tier" {
  name     = "scalable-webapp-app-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/health"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "scalable-webapp-app-tg"
  }
}

# Target Group for Web Tier
resource "aws_lb_target_group" "web_tier" {
  name     = "scalable-webapp-web-tg"
  port     = var.web_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/health"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "scalable-webapp-web-tg"
  }
}

# IAM Role for EC2 Instances (Application and Web Tiers)
resource "aws_iam_role" "ec2_role" {
  name = "scalable-webapp-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "scalable-webapp-ec2-role"
  }
}

# Attach policies to the EC2 Role (e.g., CloudWatchAgentServerPolicy)
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile for the EC2 Role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "scalable-webapp-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Update Launch Templates to use the IAM Instance Profile
resource "aws_launch_template" "app_tier" {
  name_prefix   = "scalable-webapp-app-"
  image_id      = var.app_ami_id # Define this variable
  instance_type = var.app_instance_type # Define this variable
  key_name      = var.key_pair_name # Define this variable for SSH access
  vpc_security_group_ids = [aws_security_group.app_tier.id]

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 30 # GiB
      volume_type = "gp2"
    }
  }

  user_data = base64encode(var.app_user_data) # Define this variable for instance bootstrapping

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tags = {
    Name = "scalable-webapp-app-instance"
  }
}

# Auto Scaling Group for Application Tier
resource "aws_autoscaling_group" "app_tier" {
  name                = "scalable-webapp-app-asg"
  vpc_zone_identifier = aws_subnet.private_app.*.id
  desired_capacity    = var.app_desired_capacity # Define this variable
  min_size            = var.app_min_size # Define this variable
  max_size            = var.app_max_size # Define this variable

  launch_template {
    id      = aws_launch_template.app_tier.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tier.arn]

  tag {
    key                 = "Name"
    value               = "scalable-webapp-app-instance"
    propagate_at_launch = true
  }

  health_check_type = "ELB"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template for Web Tier EC2 Instances
resource "aws_launch_template" "web_tier" {
  name_prefix   = "scalable-webapp-web-"
  image_id      = var.web_ami_id # Define this variable
  instance_type = var.web_instance_type # Define this variable
  key_name      = var.key_pair_name # Define this variable for SSH access
  vpc_security_group_ids = [aws_security_group.web_tier.id]

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 30 # GiB
      volume_type = "gp2"
    }
  }

  user_data = base64encode(var.web_user_data) # Define this variable for instance bootstrapping

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tags = {
    Name = "scalable-webapp-web-instance"
  }
}

# Auto Scaling Group for Web Tier
resource "aws_autoscaling_group" "web_tier" {
  name                = "scalable-webapp-web-asg"
  vpc_zone_identifier = aws_subnet.private_web.*.id
  desired_capacity    = var.web_desired_capacity # Define this variable
  min_size            = var.web_min_size # Define this variable
  max_size            = var.web_max_size # Define this variable

  launch_template {
    id      = aws_launch_template.web_tier.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tier.arn]

  tag {
    key                 = "Name"
    value               = "scalable-webapp-web-instance"
    propagate_at_launch = true
  }

  health_check_type = "ELB"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Multi-AZ Database
resource "aws_db_instance" "main" {
  allocated_storage    = var.db_allocated_storage
  storage_type       = "gp2"
  engine             = "mysql" # Assuming MySQL based on common usage, change if needed
  engine_version     = "8.0" # Specify a version
  instance_class     = var.db_instance_type
  identifier         = "scalable-webapp-rds"
  db_name            = var.db_name
  username           = var.db_username
  password           = var.db_password
  parameter_group_name = "default.mysql8.0" # Ensure this matches the engine version
  publicly_accessible = false
  multi_az           = true
  vpc_security_group_ids = [aws_security_group.db_tier.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot = true # Change to false for production
  tags = {
    Name = "scalable-webapp-rds"
  }
}

# RDS DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "scalable-webapp-db-subnet-group"
  subnet_ids = aws_subnet.private_db.*.id
  tags = {
    Name = "scalable-webapp-db-subnet-group"
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami             = var.bastion_ami_id
  instance_type   = var.bastion_instance_type
  key_name        = var.key_pair_name
  subnet_id       = element(aws_subnet.public.*.id, 0) # Place in the first public subnet
  vpc_security_group_ids = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    Name = "scalable-webapp-bastion"
  }
}

# Route 53 A Record for the ALB
resource "aws_route53_record" "webapp" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.internet_facing.dns_name
    zone_id                = aws_lb.internet_facing.zone_id
    evaluate_target_health = true
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "scalable-webapp-alerts"
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

# Example CloudWatch Alarm for ALB Latency
resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "scalable-webapp-alb-latency-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RequestLatency"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0.5 # Define a suitable threshold
  alarm_description   = "Alarm when ALB latency is too high."

  dimensions = {
    LoadBalancer = aws_lb.internet_facing.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Example CloudWatch Alarm for Auto Scaling Group CPU Utilization (App Tier)
resource "aws_cloudwatch_metric_alarm" "app_cpu_utilization" {
  alarm_name          = "scalable-webapp-app-cpu-utilization-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 75 # Define a suitable threshold
  alarm_description   = "Alarm when Application Tier CPU utilization is high."

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_tier.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Example CloudWatch Alarm for RDS CPU Utilization
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  alarm_name          = "scalable-webapp-rds-cpu-utilization-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 75 # Define a suitable threshold
  alarm_description   = "Alarm when RDS CPU utilization is high."

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# NAT Gateway (Optional - uncomment if needed for outbound internet from private subnets)
# NOTE: NAT Gateway is NOT typically covered by the AWS Free Tier and can incur significant costs based on usage and data processing.
# Consider using a NAT instance (an EC2 instance configured for NAT) if cost is a major concern, although it's less highly available.
/*
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(aws_subnet.public.*.id, 0) # Place in one of the public subnets

  tags = {
    Name = "scalable-webapp-nat-gateway"
  }
}

resource "aws_eip" "nat" {
  tags = {
    Name = "scalable-webapp-nat-eip"
  }
}

# Update Private Route Table to use NAT Gateway
resource "aws_route" "private_nat" {
  count              = length(aws_subnet.private_app) + length(aws_subnet.private_web) + length(aws_subnet.private_db)
  route_table_id     = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id     = aws_nat_gateway.main.id

  # Ensure this route is only created if the NAT Gateway resources are defined
  depends_on = [
    aws_nat_gateway.main,
    aws_eip.nat,
  ]
}
*/ 