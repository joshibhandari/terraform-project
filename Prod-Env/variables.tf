variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "vpc_name" {
  description = "name for the vpc"
  type        = string 
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
}

variable "aws_region" {
  description = "aws region is"
  type = string
}

variable "instance_type" {
  description = "instance type"
  type = string
}

variable "ami" {
  description = "provide a ami for the vm"
  type = string
}

variable "security_group_ingress" {
  description = "List of maps of ingress rules to set on the security group"
  type        = list(map(string))
  default = [
  {
    self             = true
    cidr_blocks      = "0.0.0.0/0"
    ipv6_cidr_blocks = "::/0"
    prefix_list_ids  = ""
    security_groups  = ""
    description      = "Allow all inbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
  },
  {
    self             = false
    cidr_blocks      = "192.168.1.0/24"
    ipv6_cidr_blocks = ""
    prefix_list_ids  = ""
    security_groups  = ""
    description      = "Allow inbound traffic from a specific CIDR"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
  }
]
}

variable "security_group_egress" {
  description = "List of maps of egress rules to set on the security group"
  type        = list(map(string))
  default = [
  {
    self             = true
    cidr_blocks      = "0.0.0.0/0"
    ipv6_cidr_blocks = "::/0"
    prefix_list_ids  = ""
    security_groups  = ""
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
  }
]
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = "igw"
}

variable "reuse_nat_ips" {
  description = "Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external_nat_ip_ids' variable"
  type        = bool
  default     = false
}

# variable "instance_type" {
#   description = "Name of the project"
#   type        = string
#   default     = "t2.micro"
# }

variable "key_name" {
  description = "Name of the key pair"
  type        = string
}

variable "public_instance_per_subnet" {
  description = "Number of amazon linux host"
  type        = number
}

variable "private_instance_per_subnet" {
  description = "Number of amazon linux host"
  type        = number
}

variable "private_instance_name" {
  description = "A list of private instance name"
  type = list(string)
}

variable "public_instance_name" {
  description = "Alist of private instance name"
  type = list(string)
}

variable "private_key_location" {
  description = "Location of the private key"
  type        = string
}

variable "public_instance_sg_ports" {

  description = "Define the ports and protocols for the security group"
  type        = list(any)
  default = [
    {
      "port" : 22,
      "protocol" : "tcp"
    },
  ]
}

variable "private_instance_sg_ports" {

  description = "Define the ports and protocols for the security group"
  type        = list(any)
  default = [
    {
      "port" : 22,
      "protocol" : "tcp"
    },
    {
      "port" : -1,
      "protocol" : "icmp"
    }
  ]
}

variable "public_instance_conf" {
  description = "Configuration for public instances"
  type        = list(object({
    ami                    = string
    instance_type          = string
    subnet_id              = string
    key_name               = string
    vpc_security_group_ids = list(string)
    user_data              = string
  }))
}

variable "private_instance_conf" {
  description = "Configuration for private instances"
  type        = list(object({
    ami                    = string
    instance_type          = string
    subnet_id              = string
    key_name               = string
    vpc_security_group_ids = list(string)
  }))
}

variable "resource_name" {
  description = "name for the resource"
  default = "prod"
}

variable "profile" {
  description = "profile name to provision infra"
  type = string
}

variable "user_data" {
  description = "the set of commands/data you can provide to a instance at launch time"
  type = string
}