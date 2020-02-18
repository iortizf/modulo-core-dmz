variable "nombre-proyecto" {}
variable "sufijo-proyecto" {}
variable "dmz-cidr" {
  default = "10.96.237.64/26"
}
variable "public-subnets" {
  type = list(string)
  default = ["10.96.237.64/27"]
}
variable "private-subnets" {
  type = list(string)
  default = ["10.96.237.64/27"]
}
variable "nat-required" {
  type = bool
  default = true
}




