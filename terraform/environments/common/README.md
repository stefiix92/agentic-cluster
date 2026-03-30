# Common environment stack

Shared **root module** fragments used by every environment under `environments/<name>/`.

Each environment directory should **symlink** the `.tf` files from here and keep **only env-local** files in its folder (for example `terraform.tfvars`, `backend.hcl`, or a small `locals.tf` if you truly need an override).

## Symlink pattern

From `environments/dev/`:

```bash
ln -sf ../common/versions.tf .
ln -sf ../common/providers.tf .
ln -sf ../common/data.tf .
ln -sf ../common/main.tf .
ln -sf ../common/variables.tf .
ln -sf ../common/outputs.tf .
```

Add more shared files to `common/` and symlink them the same way.

**Module paths** inside these files are written relative to `common/` (`../../modules/...`), which matches the path depth from any `environments/<env>/` working directory.

Notes on what `common/main.tf` actually does:

- installs `sealed-secrets`
- installs `aws-load-balancer-controller`
- installs `argocd` (namespace `argo`)
- creates the `root-platform` app-of-apps manifest (`kubernetes_manifest.argocd_root_application`)
