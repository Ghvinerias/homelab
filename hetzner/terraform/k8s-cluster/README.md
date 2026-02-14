## Hetzner / Cloudflare Terraform Stack

Infrastructure as code for the external (Hetzner + Cloudflare) layer of the homelab. These configs provision networking primitives, DNS, firewall rules, secrets injection, and bootstrap hooks that hand off to Ansible for host configuration.

### 📦 Contents

| File | Purpose |
|------|---------|
| `main.tf` | Root module wiring: required providers, backend/state (OpenTofu/Terraform local), module composition. |
| `firewalls_and_networks.tf` | Hetzner Cloud networks, firewalls, security groups. |
| `cloudflare.tf` | Cloudflare zones, DNS records, rulesets, Access / Email routing (delegates some zone-specific config). |
| `bitwarden_data.tf` | Pulls secrets from Bitwarden vault via `sebastiaan-dev/bitwarden-secrets` provider. |
| `ansible.tf` | Drops rendered inventory / helper artifacts to feed subsequent Ansible playbooks. |
| `.terraform.lock.hcl` | Provider dependency lock; commit to ensure repeatable provider versions. |

Providers in use:
- `hetznercloud/hcloud` (servers, networks, firewalls)
- `cloudflare/cloudflare` (DNS, Access, Email routing, rulesets)
- `sebastiaan-dev/bitwarden-secrets` (secret retrieval)
- `hashicorp/kubernetes` + `hashicorp/helm` (optional bootstrap interactions with k8s cluster objects / charts)
- `hashicorp/local`, `hashicorp/null` (local file artifacts, orchestration glue)

### ✅ Prerequisites

On macOS (zsh assumed):
1. OpenTofu or Terraform CLI installed (`brew install opentofu` or `brew install terraform`).
2. Access credentials:
	- Hetzner Cloud API token exported: `export HCLOUD_TOKEN=...`
	- Cloudflare API token with DNS + Zone + Rulesets + Workers (if used): `export CLOUDFLARE_API_TOKEN=...`
	- Bitwarden session (for the BW provider) or BW credentials; commonly: `export BW_SESSION=$(bw unlock --raw)` and ensure `bw` CLI logged in.
3. (Optional) Kubeconfig present if using kubernetes/helm resources: `export KUBECONFIG=~/path/to/kube_config`.
4. Clone repo and `cd hetzner/terraform`.

### 🔐 Secrets & Auth Flow

Bitwarden provider reads items by UUID or name; keep secret identifiers out of the repo when possible. Avoid committing `.vault_pass` or plaintext secrets—only references.

### 🚀 Usage

Initialize providers:
```bash
tofu init
```

Validate syntax and provider schemas:
```bash
tofu validate
```

Plan (dry-run infrastructure changes):
```bash
tofu plan -out tfplan
```

Apply (execute changes):
```bash
tofu apply tfplan
```

Or directly:
```bash
tofu apply -auto-approve
```

Destroy (tear everything down — be careful):
```bash
tofu destroy
```

Targeting a specific file/resource example:
```bash
tofu plan -target=hcloud_firewall.default
```

### 🔄 Ansible Integration

`ansible.tf` can render dynamic inventory or host vars after provisioning (e.g., server IPs). After `apply`, run:
```bash
ansible-playbook ../../Ansible/playbooks/site.yml --ask-vault-pass --limit <new_host_group>
```
Use `--check` for dry-runs.

### 🛠 Common Environment Exports
```bash
export HCLOUD_TOKEN=...         # Hetzner API
export CLOUDFLARE_API_TOKEN=... # Cloudflare API
export BW_SESSION=$(bw unlock --raw)
export TF_VAR_cloudflare_account_id=...  # if required by zone/account scoped resources
```

Place transient helper outputs (generated inventory, etc.) in ignored paths when possible.

### 🧪 Quick Smoke Test
After `tofu init` run:
```bash
tofu plan -target=null_resource.smoke
```
If no such resource exists you can add a lightweight `null_resource` for dependency validation.

### 🧭 Troubleshooting
| Symptom | Hint |
|---------|------|
| Provider auth failures | Check exported tokens & `bw status`. Regenerate session if expired. |
| Drift between runs | Refresh with `tofu plan -refresh=true` and confirm no manual edits occurred. |
| Bitwarden item not found | Verify UUID, item is in the logged-in account, session active. |
| Cloudflare errors on Access/Email | Token scopes insufficient — reissue with needed permissions. |

### 📐 Style & Conventions
- Keep resource naming consistent: prefix with `homelab-` or environment (e.g., `hl-`).
- Group related records/rules into their own `.tf` logically; limit file sprawl.
- Prefer variables over hard-coded IDs (pass via `TF_VAR_*`).

### 🚧 Future Enhancements
- Remote state backend (e.g., S3, GCS, or Hetzner Storage Box) for team collaboration.
- Add automated `terraform-docs` generation into CI.
- Integrate with GitHub Actions for plan previews on PRs.
- Add module wrappers if resource count grows (network, dns, security modules).

### 📝 License / Attribution
Provider binaries are third-party; see their respective `LICENSE` files under `.terraform/providers/`. Repository itself follows the root project license (see top-level `README.md`).