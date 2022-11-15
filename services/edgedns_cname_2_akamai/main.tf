# our terraform module to create TXT records for secure by default
# zone should already be active!
terraform {
  required_providers {
    akamai = {
      source = "akamai/akamai"
      #version = "1.9.1"
    }
  }
}

/* # for cloud usage these vars have been defined in terraform cloud as a set
# Configure the Akamai Provider to use separete EdgeDNS credentials
provider "akamai" {
  edgerc         = "~/.edgerc"
  config_section = "gss_training"
} */


# create a single CNAME record to point to akamai
resource "akamai_dns_record" "akamai_cname" {

  # get the key or value, same in this instance 
  zone = regex("([\\w-]*)\\.([\\w-\\.]*)", var.hostname)[1]
  name = var.hostname

  # let's lookup target value from our map of maps with value from hostnames[] as key
  target = [var.edge_hostname]

  # TTL of CNAME should be longer but for demo it's fine.
  recordtype = "CNAME"
  active     = true
  ttl        = 60
}
