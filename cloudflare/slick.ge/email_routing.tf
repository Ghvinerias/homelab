# Email Routing Rules

# Email Rule: Rule created at 2024-10-25T07:21:07.376Z
resource "cloudflare_email_routing_rule" "slick_ge_email_rule_created_at_2024_10_25t07_21_07_376z_0d7f8e26" {
  zone_id  = cloudflare_zone.slick_ge.id
  name     = "Rule created at 2024-10-25T07:21:07.376Z"
  enabled  = true
  priority = 0
  matcher {
    type  = "literal"
    field = "to"
    value = data.bitwarden-secrets_secret.c1f9a7ac7334dd09ff3b37f01405646.value
  }
  action {
    type  = "forward"
    value = [data.bitwarden-secrets_secret.CF_EMAIL_ROUTE_DESTINATION.value]
  }
}

# Email Rule: Rule created at 2023-11-17T09:34:56.573Z
resource "cloudflare_email_routing_rule" "slick_ge_email_rule_created_at_2023_11_17t09_34_56_573z_2e5c8f6b" {
  zone_id  = cloudflare_zone.slick_ge.id
  name     = "Rule created at 2023-11-17T09:34:56.573Z"
  enabled  = true
  priority = 0
  matcher {
    type  = "literal"
    field = "to"
    value = data.bitwarden-secrets_secret.e9ad442b7cc74ff3ac2eb37f0149aa86.value
  }
  action {
    type  = "forward"
    value = [data.bitwarden-secrets_secret.CF_EMAIL_ROUTE_DESTINATION.value]
  }
}

# Email Rule: Rule created at 2023-08-25T07:53:24.110Z
resource "cloudflare_email_routing_rule" "slick_ge_email_rule_created_at_2023_08_25t07_53_24_110z_e54161b8" {
  zone_id  = cloudflare_zone.slick_ge.id
  name     = "Rule created at 2023-08-25T07:53:24.110Z"
  enabled  = true
  priority = 0
  matcher {
    type  = "literal"
    field = "to"
    value = data.bitwarden-secrets_secret.de90cdad7bec475eb4b0b37f014a0e08.value
  }
  action {
    type  = "forward"
    value = [data.bitwarden-secrets_secret.CF_EMAIL_ROUTE_DESTINATION.value]
  }
}

# Email Rule: Rule created at 2023-08-25T07:40:23.782Z
resource "cloudflare_email_routing_rule" "slick_ge_email_rule_created_at_2023_08_25t07_40_23_782z_0c2395dd" {
  zone_id  = cloudflare_zone.slick_ge.id
  name     = "Rule created at 2023-08-25T07:40:23.782Z"
  enabled  = true
  priority = 0
  matcher {
    type  = "literal"
    field = "to"
    value = data.bitwarden-secrets_secret.a5a474ff3f14024b2abb37f014a5e4a.value
  }
  action {
    type  = "forward"
    value = [data.bitwarden-secrets_secret.CF_EMAIL_ROUTE_DESTINATION.value]
  }
}

# Email Rule: Rule created at 2022-02-25T07:54:14.330Z
resource "cloudflare_email_routing_rule" "slick_ge_email_rule_created_at_2022_02_25t07_54_14_330z_5aba46d9" {
  zone_id  = cloudflare_zone.slick_ge.id
  name     = "Rule created at 2022-02-25T07:54:14.330Z"
  enabled  = true
  priority = 0
  matcher {
    type  = "literal"
    field = "to"
    value = data.bitwarden-secrets_secret.c0e1aee9e9e248949fefb37f014ac468.value
  }
  action {
    type  = "forward"
    value = [data.bitwarden-secrets_secret.CF_EMAIL_ROUTE_DESTINATION.value]
  }
}

# Email Rule: Rule created at 2022-02-01T06:54:05.921Z
resource "cloudflare_email_routing_rule" "slick_ge_email_rule_created_at_2022_02_01t06_54_05_921z_7dccea3a" {
  zone_id  = cloudflare_zone.slick_ge.id
  name     = "Rule created at 2022-02-01T06:54:05.921Z"
  enabled  = true
  priority = 0
  matcher {
    type  = "literal"
    field = "to"
    value = data.bitwarden-secrets_secret.fd4c1a3f3142db8385b37f014b1aa7.value
  }
  action {
    type  = "forward"
    value = [data.bitwarden-secrets_secret.CF_EMAIL_ROUTE_DESTINATION.value]
  }
}

# Email Rule: Rule created at 2022-01-23T21:34:39.741Z
resource "cloudflare_email_routing_rule" "slick_ge_email_rule_created_at_2022_01_23t21_34_39_741z_cb7953c6" {
  zone_id  = cloudflare_zone.slick_ge.id
  name     = "Rule created at 2022-01-23T21:34:39.741Z"
  enabled  = true
  priority = 0
  matcher {
    type  = "literal"
    field = "to"
    value = data.bitwarden-secrets_secret.d8cf1c43be5a4e8ebfdfb37f014b9281.value
  }
  action {
    type  = "forward"
    value = [data.bitwarden-secrets_secret.CF_EMAIL_ROUTE_DESTINATION.value]
  }
}

# Email Rule: Rule created at 2022-01-11T16:47:02.596Z
resource "cloudflare_email_routing_rule" "slick_ge_email_rule_created_at_2022_01_11t16_47_02_596z_bbd4e22c" {
  zone_id  = cloudflare_zone.slick_ge.id
  name     = "Rule created at 2022-01-11T16:47:02.596Z"
  enabled  = true
  priority = 0
  matcher {
    type  = "literal"
    field = "to"
    value = data.bitwarden-secrets_secret.fa674bfb94baf8edcb37f014c1579.value
  }
  action {
    type  = "forward"
    value = [data.bitwarden-secrets_secret.CF_EMAIL_ROUTE_DESTINATION.value]
  }
}

