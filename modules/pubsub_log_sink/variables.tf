variable "enabled" {
  type        = bool
  description = "Whether to create the PubSub + logging sink stack at all. When false, the module creates no resources. Typically driven by the product's DT-managed / use_pubsub toggle."
}

variable "organisation_id" {
  type        = string
  description = "The Organisation in which the sink is created for unscoped (org-level) deployments"
}

variable "allowed_projects" {
  type        = set(string)
  description = "The set of allowed projects for scoped deployment. When non-empty, per-project sinks are created instead of an org-level sink"
  default     = []
}

variable "topic_name" {
  type        = string
  description = "Name of the PubSub topic to create"
}

variable "subscription_name" {
  type        = string
  description = "Name of the PubSub subscription to create against the topic"
}

variable "sink_name" {
  type        = string
  description = "Name of the logging sink (used for both the org-level and per-project sinks)"
}

variable "sink_description" {
  type        = string
  description = "Description applied to the org-level logging sink"
  default     = ""
}

variable "sink_filter" {
  type        = string
  description = "The filter defining which logs are routed to the topic"
}

variable "sink_exclusion" {
  type = object({
    name   = string
    filter = string
  })
  description = "Optional exclusion filter applied to the sink. When null, no exclusion block is added"
  default     = null
}

variable "publisher_project" {
  type        = string
  description = "The project in which the sink writer identity is granted roles/pubsub.publisher. This is where the topic lives"
}

variable "subscriber_member" {
  type        = string
  description = "The service account member to grant roles/pubsub.subscriber on the subscription's project. Only used when subscriber_binding_enabled is true"
  default     = ""
}

variable "subscriber_project" {
  type        = string
  description = "The project in which the subscriber member is granted roles/pubsub.subscriber. When empty, defaults to publisher_project. For customer-supplied subscriptions this is the project that owns the subscription"
  default     = ""
}

variable "subscriber_binding_enabled" {
  type        = bool
  description = "Whether to create the subscriber binding. Unlike the sink stack (gated by var.enabled), the subscriber binding may be needed even when no DT-managed infrastructure is created — e.g. when a customer supplies their own subscription. This is a plain boolean (not derived from subscriber_member) so the count stays known at plan time even when the member is computed. Defaults to false; products opt in explicitly"
  default     = false
}
