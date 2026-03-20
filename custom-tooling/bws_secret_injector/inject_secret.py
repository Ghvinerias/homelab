#!/usr/bin/env python3
"""
inject_secret.py

Encrypts a secret value using the target repository's public key (NaCl
sealed box, as required by the GitHub Actions secrets API) and writes it
as an Actions secret via the GitHub REST API.

GitHub requires client-side encryption — the raw value is never transmitted
over the wire.

Required environment variables:
  GH_PAT        - GitHub PAT (or token) with secrets:write on the target repo
  TARGET_REPO   - Target repository in "owner/repo" format
  SECRET_NAME   - Name of the Actions secret to create/update
  SECRET_VALUE  - The plaintext secret value to encrypt and store
"""

import os
import sys
import base64

import requests
from nacl import public


API = "https://api.github.com"
HEADERS = {
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
}


def get_env(key: str) -> str:
    value = os.environ.get(key, "").strip()
    if not value:
        print(f"[ERROR] Required environment variable '{key}' is not set.", file=sys.stderr)
        sys.exit(1)
    return value


def auth_headers(pat: str) -> dict:
    return {**HEADERS, "Authorization": f"Bearer {pat}"}


def get_repo_public_key(pat: str, owner: str, repo: str) -> tuple[str, str]:
    """
    Fetch the repository's public key for secret encryption.
    Returns (key_id, base64_public_key).
    """
    url = f"{API}/repos/{owner}/{repo}/actions/secrets/public-key"
    resp = requests.get(url, headers=auth_headers(pat))

    if resp.status_code == 403:
        print(
            "[ERROR] 403 Forbidden — the GH_PROVISIONER_PAT does not have "
            "secrets:write permission on the target repository.",
            file=sys.stderr,
        )
        sys.exit(1)

    if resp.status_code == 404:
        print(
            f"[ERROR] Repository '{owner}/{repo}' not found or the token "
            "cannot access it.",
            file=sys.stderr,
        )
        sys.exit(1)

    resp.raise_for_status()
    data = resp.json()
    return data["key_id"], data["key"]


def encrypt_secret(public_key_b64: str, secret_value: str) -> str:
    """
    Encrypt secret_value using a NaCl sealed box with the repo's public key.
    Returns a base64-encoded ciphertext, as expected by the GitHub API.
    """
    public_key_bytes = base64.b64decode(public_key_b64)
    sealed_box = public.SealedBox(public.PublicKey(public_key_bytes))
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    return base64.b64encode(encrypted).decode("utf-8")


def put_secret(
    pat: str,
    owner: str,
    repo: str,
    secret_name: str,
    encrypted_value: str,
    key_id: str,
) -> None:
    """
    Create or update an Actions secret on the target repository.
    The GitHub API is idempotent — PUT upserts.
    """
    url = f"{API}/repos/{owner}/{repo}/actions/secrets/{secret_name}"
    payload = {
        "encrypted_value": encrypted_value,
        "key_id": key_id,
    }
    resp = requests.put(url, headers=auth_headers(pat), json=payload)

    if resp.status_code in (201, 204):
        action = "Created" if resp.status_code == 201 else "Updated"
        print(f"[INFO] {action} Actions secret '{secret_name}' on {owner}/{repo}.")
        return

    resp.raise_for_status()


def verify_secret_exists(pat: str, owner: str, repo: str, secret_name: str) -> None:
    """
    Confirm the secret appears in the repository's secret list.
    (GitHub does not expose the value — we can only confirm the key exists.)
    """
    url = f"{API}/repos/{owner}/{repo}/actions/secrets/{secret_name}"
    resp = requests.get(url, headers=auth_headers(pat))
    if resp.status_code == 200:
        created_at = resp.json().get("created_at", "unknown")
        updated_at = resp.json().get("updated_at", "unknown")
        print(f"[INFO] Verification passed — secret exists. updated_at={updated_at}")
    else:
        print(
            f"[WARN] Could not verify secret existence (HTTP {resp.status_code}). "
            "The PUT may still have succeeded.",
            file=sys.stderr,
        )


def main() -> None:
    pat = get_env("GH_PAT")
    target_repo = get_env("TARGET_REPO")
    secret_name = get_env("SECRET_NAME")
    secret_value = get_env("SECRET_VALUE")

    # Mask the secret value immediately
    print(f"::add-mask::{secret_value}")

    if "/" not in target_repo:
        print(
            f"[ERROR] TARGET_REPO must be in 'owner/repo' format, got: '{target_repo}'",
            file=sys.stderr,
        )
        sys.exit(1)

    owner, repo = target_repo.split("/", 1)

    print(f"[INFO] Fetching public key for {owner}/{repo}")
    key_id, public_key_b64 = get_repo_public_key(pat, owner, repo)
    print(f"[INFO] Got public key (key_id={key_id})")

    print(f"[INFO] Encrypting secret value")
    encrypted = encrypt_secret(public_key_b64, secret_value)

    print(f"[INFO] Writing secret '{secret_name}' to {owner}/{repo}")
    put_secret(pat, owner, repo, secret_name, encrypted, key_id)

    verify_secret_exists(pat, owner, repo, secret_name)
    print("[INFO] inject_secret.py completed successfully.")


if __name__ == "__main__":
    main()