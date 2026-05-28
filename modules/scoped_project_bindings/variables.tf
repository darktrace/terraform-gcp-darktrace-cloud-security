variable "role_id" {
  type        = string
  description = "The ID of the role being bound"
}

variable "projects" {
  type        = set(string)
  description = "The projects in which to create roll bindings"
}

variable "member" {
  type        = string
  description = "The member to be bound"
}
