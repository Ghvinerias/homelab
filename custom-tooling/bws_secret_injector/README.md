# Repository Provisioning Automation

Copies the `BWS_ACCESS_TOKEN` secret stored in this (`.github`) repo into a
target repository as an Actions secret, so new repos can immediately use
Bitwarden Secrets Manager without any manual secret setup.

---

## How it works

```
workflow_dispatch
│  input: target_repo (owner/repo)
│
└─► inject_secret.py
      │
      ├─ GET  api.github.com/repos/{owner}/{repo}/actions/secrets/public-key
      │       ← { key_id, key }
      │
      ├─ NaCl SealedBox.encrypt(BWS_ACCESS_TOKEN, repo_public_key)
      │
      └─ PUT  api.github.com/repos/{owner}/{repo}/actions/secrets/BWS_ACCESS_TOKEN
              ← 201 Created / 204 Updated
```

The secret value never touches disk — it flows from the runner's environment
directly into the encrypted payload sent to the GitHub API.

---

## Setup

### 1. Secrets on this repo

| Secret | Description |
|---|---|
| `BWS_ACCESS_TOKEN` | The Bitwarden machine account access token to propagate |
| `GH_PROVISIONER_PAT` | GitHub PAT with **Secrets: Read and write** on target repos |

**Creating `BWS_ACCESS_TOKEN`:**
1. Open Bitwarden Secrets Manager
2. Go to **Machine accounts** → your machine account → **Access tokens**
3. Click **Create access token**, copy the value immediately (shown once)
4. Save it as `BWS_ACCESS_TOKEN` in this repo's secrets

**Creating `GH_PROVISIONER_PAT`:**
1. GitHub → **Settings → Developer settings → Fine-grained personal access tokens**
2. **Generate new token**
3. Set **Resource owner** to your org or account
4. Under **Repository access** select the repos you'll provision (or all repos)
5. Under **Permissions → Repository permissions** set **Secrets** to **Read and write**
6. Save the token as `GH_PROVISIONER_PAT` in this repo's secrets

### 2. File layout

```
.github/
├── workflows/
│   └── provision-repo.yml    # Workflow definition
└── custom-tooling/bws_secret_injector/
    ├── requirements.txt       # requests, PyNaCl
    └── inject_secret.py       # Encrypts and injects the secret
```

---

## Running

Go to **Actions → Provision Repository → Run workflow**, enter the target repo
in `owner/repo` format (e.g. `Ghvinerias/my-new-service`), and click
**Run workflow**.

After it completes the target repo will have `BWS_ACCESS_TOKEN` available as
an Actions secret. Any workflow there can use it immediately:

```yaml
- uses: bitwarden/sm-action@v2
  with:
    access_token: ${{ secrets.BWS_ACCESS_TOKEN }}
    secrets: |
      <secret-id> > MY_SECRET
```

---

## Rotating the token

When you rotate the machine account token in Bitwarden:

1. Update `BWS_ACCESS_TOKEN` in this repo's secrets with the new value
2. Re-run **Provision Repository** for each repo that needs the updated token