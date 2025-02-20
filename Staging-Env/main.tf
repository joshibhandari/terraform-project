locals {
  public_subnets  = module.vpc.public_subnet_ids
  private_subnets = module.vpc.private_subnet_ids
  vpc_id          = module.vpc.vpc_id

  public_instance_conf = flatten([
    for index, subnet in var.public_subnets : [
      for i in range(var.public_instance_per_subnet) : {
        ami                    = var.ami
        instance_type          = var.instance_type
        subnet_id              = local.public_subnets[0] 
        key_name               = var.key_name
        vpc_security_group_ids = [module.ec2.public_security_group_id]
        user_data              = var.user_data
      }
    ]
  ])

  private_instance_conf = flatten([
    for index, subnet in var.private_subnets : [
      for i in range(var.private_instance_per_subnet) : {
        ami                    = var.ami
        instance_type          = var.instance_type
        subnet_id              = local.private_subnets[0] 
        key_name               = var.key_name
        vpc_security_group_ids = [module.ec2.private_security_group_id]
      }
    ]
  ])
}

module "vpc" {
  source = "./modules/vpc"
  vpc_name = var.vpc_name
  cidr = var.cidr
  azs = var.azs
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  resource_name = var.key_name
  security_group_ingress = var.security_group_ingress
  security_group_egress = var.security_group_egress
}

module "ec2" {
  source = "./modules/ec2"
  vpc_id                        = module.vpc.vpc_id
  public_subnets                = module.vpc.public_subnet_ids
  private_subnets               = module.vpc.private_subnet_ids
  instance_type = var.instance_type
  public_instance_sg_ports      = var.public_instance_sg_ports
  private_instance_sg_ports     = var.private_instance_sg_ports
  public_instance_per_subnet    = var.public_instance_per_subnet
  private_instance_per_subnet   = var.private_instance_per_subnet
  private_key_location          = var.private_key_location
  key_name                      = var.key_name
  private_instance_name         = var.private_instance_name
  public_instance_name          = var.public_instance_name
  public_instance_conf          = local.public_instance_conf
  private_instance_conf         = local.private_instance_conf

}