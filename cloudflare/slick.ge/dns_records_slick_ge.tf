# record_id: ddf2824cf6d85d64e72b7b94e7c9cb85
resource "cloudflare_record" "slick_ge_cloud_slick_ge_ddf2824cf6d85d64e72b7b94e7c9cb85" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "cloud.slick.ge"
  type    = "A"
  content   = data.bitwarden-secrets_secret.slick_ge_cloud_slick_ge_ddf2824cf6d85d64e72b7b94e7c9cb85_ip.value
  ttl     = 1
  proxied = true
}
# record_id: 56ddc1b8d046ddee50c7b60afac4f48c
resource "cloudflare_record" "slick_ge_wildcard_cloud_slick_ge_56ddc1b8d046ddee50c7b60afac4f48c" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "*.cloud.slick.ge"
  type    = "CNAME"
  content   = "cloud.slick.ge"
  ttl     = 1
  proxied = false
}

resource "cloudflare_record" "slick_ge_k8s_cloud_slick_ge" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "k8s.cloud.slick.ge"
  type    = "A"
  content   = data.bitwarden-secrets_secret.slick_ge_k8s_cloud_slick_ge_ip.value
  ttl     = 1
  proxied = false
}
# record_id: 56ddc1b8d046ddee50c7b60afac4f48c
resource "cloudflare_record" "slick_ge_wildcard_k8s_cloud_slick_ge" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "*.k8s.cloud.slick.ge"
  type    = "CNAME"
  content   = "k8s.cloud.slick.ge"
  ttl     = 1
  proxied = true
}

# record_id: 697591ad43036c56b3530335c311fe82
resource "cloudflare_record" "slick_ge_varagaradu_slick_ge_697591ad43036c56b3530335c311fe82" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "varagaradu.slick.ge"
  type    = "A"
  content   = data.bitwarden-secrets_secret.slick_ge_varagaradu_slick_ge_697591ad43036c56b3530335c311fe82_ip.value
  ttl     = 1
  proxied = false
}

# record_id: 14fb41467f3da07fbbb9567da31b90bc
resource "cloudflare_record" "slick_ge__acme_challenge_ha_slick_ge_14fb41467f3da07fbbb9567da31b90bc" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "_acme-challenge.ha.slick.ge"
  type    = "CNAME"
  content   = "_acme-challenge.h0jkxy235xmc7dp4b41z68vk3jrw5oei.ui.nabu.casa"
  ttl     = 1
  proxied = false
}

# record_id: 8beb24b9a45e0aa88e5561125279cb81
resource "cloudflare_record" "slick_ge_auth_slick_ge_8beb24b9a45e0aa88e5561125279cb81" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "auth.slick.ge"
  type    = "CNAME"
  content   = "k8s.slick.ge"
  ttl     = 1
  proxied = false
}



# record_id: bbb2a244bc5c3d7e0b266226de5c1940
resource "cloudflare_record" "slick_ge_em543_slick_ge_bbb2a244bc5c3d7e0b266226de5c1940" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "em543.slick.ge"
  type    = "CNAME"
  content   = "u36850145.wl146.sendgrid.net"
  ttl     = 1
  proxied = false
}

# record_id: 66eeb9f263b5a0e52b04c3abd9484def
resource "cloudflare_record" "slick_ge_em5600_mail_slick_ge_66eeb9f263b5a0e52b04c3abd9484def" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "em5600.mail.slick.ge"
  type    = "CNAME"
  content   = "u36850145.wl146.sendgrid.net"
  ttl     = 1
  proxied = false
}

# record_id: 12902d641843e070f8cb3bad003463aa
resource "cloudflare_record" "slick_ge_ha_slick_ge_12902d641843e070f8cb3bad003463aa" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "ha.slick.ge"
  type    = "CNAME"
  content   = "h0jkxy235xmc7dp4b41z68vk3jrw5oei.ui.nabu.casa"
  ttl     = 1
  proxied = false
}

# record_id: 516d33a5348bfa4121a1509c19324a5a
resource "cloudflare_record" "slick_ge_s1__domainkey_mail_slick_ge_516d33a5348bfa4121a1509c19324a5a" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "s1._domainkey.mail.slick.ge"
  type    = "CNAME"
  content   = "s1.domainkey.u36850145.wl146.sendgrid.net"
  ttl     = 1
  proxied = false
}

# record_id: c007ea0bb79b15a4ce28bc216bdadadc
resource "cloudflare_record" "slick_ge_s1__domainkey_slick_ge_c007ea0bb79b15a4ce28bc216bdadadc" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "s1._domainkey.slick.ge"
  type    = "CNAME"
  content   = "s1.domainkey.u36850145.wl146.sendgrid.net"
  ttl     = 1
  proxied = false
}

# record_id: 42fdf3927929f5c32b1909ab1add83cd
resource "cloudflare_record" "slick_ge_s2__domainkey_mail_slick_ge_42fdf3927929f5c32b1909ab1add83cd" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "s2._domainkey.mail.slick.ge"
  type    = "CNAME"
  content   = "s2.domainkey.u36850145.wl146.sendgrid.net"
  ttl     = 1
  proxied = false
}

# record_id: 7da3589d3625e96c0c8973793fb17673
resource "cloudflare_record" "slick_ge_s2__domainkey_slick_ge_7da3589d3625e96c0c8973793fb17673" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "s2._domainkey.slick.ge"
  type    = "CNAME"
  content   = "s2.domainkey.u36850145.wl146.sendgrid.net"
  ttl     = 1
  proxied = false
}

# record_id: 3e841163ed071d795fe41a0f74ed14f1
resource "cloudflare_record" "slick_ge__dmarc_slick_ge_3e841163ed071d795fe41a0f74ed14f1" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "_dmarc.slick.ge"
  type    = "TXT"
  content   = "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;"
  ttl     = 1
  proxied = false
}

# record_id: 49079ee2e2e8d1ba2c5b333d3fe0cfc4
resource "cloudflare_record" "slick_ge__dmarc_slick_ge_49079ee2e2e8d1ba2c5b333d3fe0cfc4" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "_dmarc.slick.ge"
  type    = "TXT"
  content   = "v=DMARC1; p=none; rua=mailto:ghvineriaa@gmail.com"
  ttl     = 1
  proxied = false
}

# record_id: 47c2f32fd5229a93b87e04ce4b3183fa
resource "cloudflare_record" "slick_ge_wildcard_domainkey_slick_ge_47c2f32fd5229a93b87e04ce4b3183fa" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "*._domainkey.slick.ge"
  type    = "TXT"
  content   = "v=DKIM1; p="
  ttl     = 1
  proxied = false
}

# record_id: 063dd7369358106c56dd0144933fdf76
resource "cloudflare_record" "slick_ge_slick_ge_063dd7369358106c56dd0144933fdf76" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "slick.ge"
  type    = "TXT"
  content   = "protonmail-verification=44344551a32036393a290b1f1ee95f2c3d88cede"
  ttl     = 1
  proxied = false
}

# record_id: 795741803dcd98bd412cb67ee1b03466
resource "cloudflare_record" "slick_ge_slick_ge_795741803dcd98bd412cb67ee1b03466" {
  zone_id = cloudflare_zone.slick_ge.id
  name    = "slick.ge"
  type    = "TXT"
  content   = "v=spf1 include:_spf.mx.cloudflare.net ~all"
  ttl     = 1
  proxied = false
}

