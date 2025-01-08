module "sgs" {
  source         = "./modules/sg_eks"
  vpc_id         = aws_vpc.main.id
  workstation_ip = var.workstation_ip
}

module "eks" {
  source     = "./modules/eks"
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  sg_ids     = module.sgs.
  key_name  = var.key_name
}
