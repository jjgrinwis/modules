# our module to add hostnames to an existing security policy
terraform {
  required_providers {
    akamai = {
      source = "akamai/akamai"
      #version = "1.9.1"
    }
  }
}

# make use of explicit reference so you can use depends_on for example
# https://developer.hashicorp.com/terraform/language/modules/develop/providers#passing-providers-explicitly
# using the betajam account to update existing security configuration
# if switching between credentials make sure to add this provider config otherwise lookup will fail
/* provider "akamai" {
  edgerc         = "~/.edgerc"
  config_section = "betajam"
}
 */
# let's first lookup our existing security configuration
# don't expect we ever need to create a new security configuration via Terraform but it is possible
data "akamai_appsec_configuration" "security_configuration" {
  name = var.security_configuration
}

# now add our new hostname list to this security configuration
# we can only do this if hostnames are active on staging or production they won't exists otherwise and can't be added
# so make sure to use a depend_on[] before using this module
resource "akamai_appsec_selected_hostnames" "selected_hostnames" {
  config_id = data.akamai_appsec_configuration.security_configuration.id
  hostnames = var.hostnames
  mode      = "APPEND"

  /* # some special trick to create a depency with the activation of a property
  # as there is no depency it will try to add hostname before it's active.
  depends_on = [
    var.dummy
  ] */
}

# lookup the policy_id of our exisiting security_policy
data "akamai_appsec_security_policy" "specific_security_policy" {
  config_id            = data.akamai_appsec_configuration.security_configuration.config_id
  security_policy_name = var.security_policy
}

# when you have created a policy and added the hostnames to a security configuration we need to create a match target
# the match target is coming from a json file, let's make that one dynamic with our hostnames and policy_id
locals {
  template = templatefile("${path.module}/match_targets/template.tftpl", { hostnames = jsonencode(resource.akamai_appsec_selected_hostnames.selected_hostnames.hostnames), policy_id = data.akamai_appsec_security_policy.specific_security_policy.security_policy_id })
}

# just feed our created template into the match_target which is a separate resource
# this will add a new match_target to the list of match_targets for this policy.
# when destroying, this match target will be removed from security configuration match targets.
resource "akamai_appsec_match_target" "match_target" {
  config_id    = data.akamai_appsec_configuration.security_configuration.id
  match_target = local.template
}

# let's activate the latest version on staging
/* resource "akamai_appsec_activations" "activation" {
  config_id           = data.akamai_appsec_configuration.security_configuration.config_id
  network             = "STAGING"
  note                = "This configuration was activated by Terraform for testing purposes only."
  notification_emails = var.email
  version             = data.akamai_appsec_configuration.security_configuration.latest_version
} */
