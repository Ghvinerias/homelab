resource "cloudflare_ruleset" "terraform_managed_resource_9fc356b0bfe04fc78ef86973b5372557_0" {
  kind    = "zone"
  name    = "zone"
  phase   = "ddos_l7"
  zone_id = "bae8ac70807488a833254523d856e778"
  rules {
    action = "execute"
    action_parameters {
      id = "4d21379b4f9f4bb088e0729962c8b3cf"
      overrides {
        action            = "challenge"
        sensitivity_level = "default"
      }
    }
    enabled    = true
    expression = "true"
  }
}

resource "cloudflare_ruleset" "terraform_managed_resource_81d9f01d117140008947d2b843868e31_1" {
  kind    = "zone"
  name    = "default"
  phase   = "http_ratelimit"
  zone_id = "bae8ac70807488a833254523d856e778"
  rules {
    action      = "block"
    description = "test-rate"
    enabled     = true
    expression  = "(http.request.uri.path eq \"/\")"
    ratelimit {
      characteristics     = ["ip.src", "cf.colo.id"]
      mitigation_timeout  = 10
      period              = 10
      requests_per_period = 50
    }
  }
}

resource "cloudflare_ruleset" "terraform_managed_resource_d1b89f18320e4af2abe5f1ee76fabbc8_2" {
  kind    = "zone"
  name    = "default"
  phase   = "http_request_firewall_custom"
  zone_id = "bae8ac70807488a833254523d856e778"
  rules {
    action      = "block"
    description = "Block Bots"
    enabled     = true
    expression  = "(cf.client.bot)"
  }
  rules {
    action      = "block"
    description = "Threat Score 5"
    enabled     = true
    expression  = "(cf.threat_score eq 5)"
  }
}