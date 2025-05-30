variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1" # Based on diagram (N. Virginia)
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets in each availability zone."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets in each availability zone."
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets in each availability zone."
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "private_web_subnet_cidrs" {
  description = "CIDR blocks for private web subnets in each availability zone."
  type        = list(string)
  default     = ["10.0.6.0/24", "10.0.7.0/24"] # Corrected typo here based on diagram
}

variable "app_port" {
  description = "The port the application tier instances listen on."
  type        = number
  default     = 8080 # Common default for application servers
}

variable "web_port" {
  description = "The port the web tier instances listen on."
  type        = number
  default     = 80 # Common default for web servers (HTTP)
}

variable "db_port" {
  description = "The port the database instances listen on."
  type        = number
  default     = 3306 # Common default for MySQL/Aurora
}

variable "app_ami_id" {
  description = "The AMI ID for the Application Tier EC2 instances."
  type        = string
}

variable "app_instance_type" {
  description = "The instance type for the Application Tier EC2 instances."
  type        = string
  default     = "t3.micro" # Example instance type (Often Free Tier eligible)
}

variable "key_pair_name" {
  description = "The name of the EC2 key pair for SSH access."
  type        = string
}

variable "app_user_data" {
  description = "User data script for bootstrapping Application Tier instances."
  type        = string
  default     = "" # Provide a script here if needed
}

variable "app_desired_capacity" {
  description = "The desired number of Application Tier instances."
  type        = number
  default     = 2
}

variable "app_min_size" {
  description = "The minimum number of Application Tier instances."
  type        = number
  default     = 1
}

variable "app_max_size" {
  description = "The maximum number of Application Tier instances."
  type        = number
  default     = 4
}

variable "web_ami_id" {
  description = "The AMI ID for the Web Tier EC2 instances."
  type        = string
}

variable "web_instance_type" {
  description = "The instance type for the Web Tier EC2 instances."
  type        = string
  default     = "t3.micro" # Example instance type (Often Free Tier eligible)
}

variable "web_user_data" {
  description = "User data script for bootstrapping Web Tier instances."
  type        = string
  default     = "" # Provide a script here if needed
}

variable "web_desired_capacity" {
  description = "The desired number of Web Tier instances."
  type        = number
  default     = 2
}

variable "web_min_size" {
  description = "The minimum number of Web Tier instances."
  type        = number
  default     = 1
}

variable "web_max_size" {
  description = "The maximum number of Web Tier instances."
  type        = number
  default     = 4
}

variable "db_instance_type" {
  description = "The instance type for the RDS database."
  type        = string
  default     = "db.t3.micro" # Example instance type (Often Free Tier eligible for Single-AZ)
}

variable "db_allocated_storage" {
  description = "The allocated storage in GiB for the database."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "The name of the database."
  type        = string
  default     = "mydatabase"
}

variable "db_username" {
  description = "The master username for the database."
  type        = string
}

variable "db_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}

variable "bastion_ami_id" {
  description = "The AMI ID for the Bastion host EC2 instance."
  type        = string
}

variable "bastion_instance_type" {
  description = "The instance type for the Bastion host EC2 instance."
  type        = string
  default     = "t3.nano" # Small instance type sufficient for bastion (Often Free Tier eligible)
}

variable "office_ip_cidr" {
  description = "Your office IP CIDR for SSH access to the bastion host."
  type        = string
  default     = "197.35.123.103" # **Remember to replace this!**
}

variable "domain_name" {
  description = "The domain name for the web application (for Route 53)."
  type        = string
}

variable "hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for the domain name."
  type        = string
}

variable "sns_email_endpoint" {
  description = "The email address to subscribe to SNS alerts."
  type        = string
} 