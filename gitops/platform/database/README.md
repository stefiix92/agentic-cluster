# Platform: PostgreSQL (`database` namespace)

Layout: **`base/`** (shared) + **`overlays/<env>/`** (e.g. `dev/`). Argo CD `Application` targets `gitops/platform/database/overlays/<env>`. Add Helm values or raw manifests under `base/` / patches under the overlay.

Current (dev) manifests:

- `base/namespace.yaml`, `base/configmap-postgres-init.yaml`, `base/service-postgres.yaml`, `base/statefulset-postgres.yaml`
- `overlays/dev/postgres-secret.yaml` (SealedSecret: `postgres-credentials`, namespace `database`)

**PRD:** FR-3.1, FR-3.2; persistence and backup stance documented in D3.
