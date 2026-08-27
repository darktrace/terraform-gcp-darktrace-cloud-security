variable "description" {
  type        = string
  description = "The description of the created role"
}

variable "title" {
  type        = string
  description = "Role title"
}

variable "role_id" {
  type        = string
  description = "Role ID. Note if a custom prefix is required, then it should be pre-formatted by the caller"
}

variable "permissions" {
  type        = set(string)
  description = "The set of permissions added to the role"
}

variable "projects" {
  type        = set(string)
  description = "The projects in which to create the role and its binding"
}

variable "member" {
  type        = string
  description = "The member to be bound"
}
