# Cloudflare Access Applications

# Access App: Warp Login App
resource "cloudflare_zero_trust_access_application" "slick_ge_access_warp_login_app_4bfd8ca5" {
  account_id           = "010fc5d22aefa82299cbae7c50028faf"
  name                 = "Warp Login App"
  domain               = "slick.cloudflareaccess.com/warp"
  type                 = "warp"
  session_duration     = "24h"
  app_launcher_visible = false
  allowed_idps = [
    "0c108e72-b8ba-4cde-b77b-379087115c2f",
    "2ce2b1dd-d94f-4568-aa8a-bca8c628da5d",
    "43243e37-1379-40bb-932f-9f92a4c4641c"
  ]
}

# Access App: App Launcher
resource "cloudflare_zero_trust_access_application" "slick_ge_access_app_launcher_de9a9cca" {
  account_id           = "010fc5d22aefa82299cbae7c50028faf"
  name                 = "App Launcher"
  domain               = "slick.cloudflareaccess.com"
  type                 = "app_launcher"
  session_duration     = "24h"
  app_launcher_visible = false
  allowed_idps = [
    "0c108e72-b8ba-4cde-b77b-379087115c2f",
    "2ce2b1dd-d94f-4568-aa8a-bca8c628da5d"
  ]
}
