terraform {
  backend "s3" {
    # Dont forget to set these environment variables:
    #  export AWS_ACCESS_KEY_ID="YOUR_HETZNER_ACCESS_KEY"
    #  export AWS_SECRET_ACCESS_KEY="YOUR_HETZNER_SECRET_KEY"
    #  export AWS_DEFAULT_REGION="eu-central"
    bucket         = "slickg"
    key            = "homelab/cloudflare/slick.ge/terraform.tfstate"
    #region         = "eu-central"  # or any placeholder (Hetzner ignores this)
    endpoint       = "https://fsn1.your-objectstorage.com"  # Replace with your Hetzner endpoint
    #access_key     = ""
    #secret_key     = ""
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    bitwarden-secrets = {
      source  = "sebastiaan-dev/bitwarden-secrets"
      version = ">=0.1.2"
    }
  }
}
#Bitwarden related configs
provider "cloudflare" {
  api_key = data.bitwarden-secrets_secret.CF_API_TOKEN.value
  email = "ghvineriaa@gmail.com"
}

resource "cloudflare_zone" "slick_ge" {
  account_id = "010fc5d22aefa82299cbae7c50028faf"
  zone = "slick.ge"
}
output "cloudflare_zone_slick_ge_id" {
  value = cloudflare_zone.slick_ge.id
}
