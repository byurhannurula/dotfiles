# Secrets

Encrypted with [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age).
`secrets.yaml` is safe to commit — values are encrypted, keys are not.

## First-time setup

```bash
nix shell nixpkgs#age nixpkgs#sops

# 1. Generate your age key
mkdir -p "$HOME/Library/Application Support/sops/age"
age-keygen -o "$HOME/Library/Application Support/sops/age/keys.txt"

# 2. Note the public key it prints (starts with age1...)
grep 'public key' "$HOME/Library/Application Support/sops/age/keys.txt"

# 3. Put that public key into .sops.yaml (replace the placeholder)

# 4. BACK UP THE PRIVATE KEY.
#    Put keys.txt in 1Password / Bitwarden right now.
#    Lose it and every secret in this repo is gone permanently.

# 5. Create the encrypted file
sops secrets/secrets.yaml
```

## Structure of `secrets.yaml`

Keys must match the `sops.secrets` declarations in `home/secrets.nix`:

```yaml
ssh:
    id_ed25519: |
        -----BEGIN OPENSSH PRIVATE KEY-----
        ...
        -----END OPENSSH PRIVATE KEY-----
tokens:
    github: ghp_xxxxxxxxxxxx
    anthropic: sk-ant-xxxxxxxxxxxx
    openai: sk-xxxxxxxxxxxx
npmrc: |
    //registry.npmjs.org/:_authToken=npm_xxxxxxxx
```

## Daily use

```bash
sops secrets/secrets.yaml     # edit (decrypts to a temp file, re-encrypts on save)
sops -d secrets/secrets.yaml  # print decrypted to stdout
```

After editing, `rebuild` to place the new values.

## New machine

1. Restore `keys.txt` from your password manager to
   `~/Library/Application Support/sops/age/keys.txt` (mode `0600`)
2. `git clone` this repo
3. `rebuild` — SSH keys and tokens are placed automatically

## Rotating a key

Add the new age public key to `.sops.yaml`, then:

```bash
sops updatekeys secrets/secrets.yaml
```

## What must never go in here

Nothing, really — that's the point. But note that anything referenced in a
Nix *expression* (rather than read from the decrypted file at runtime) would
end up in `/nix/store`, which is world-readable. `home/secrets.nix` reads file
paths at shell startup specifically to avoid that.
