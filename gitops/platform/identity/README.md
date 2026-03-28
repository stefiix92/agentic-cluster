# Platform: Keycloak (`identity` namespace)

Layout: **`base/`** + **`overlays/<env>/`**. Argo CD points at `gitops/platform/identity/overlays/<env>`. JDBC aimed at Postgres in **`database`**.

**PRD:** FR-3.3–FR-3.5; realm/client prep for **FR-3.6** (Argo CD OIDC) documented in D2/D3.
