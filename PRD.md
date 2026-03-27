# PRD — AWS application platform (GitOps + IdP)

**Doc type:** Requirements for a reference deployment in this repository  
**Stack codename:** *agentic-cluster* (working title)

---

## 1. Intent

Ship a **minimal but credible** AWS-hosted platform: a Kubernetes cluster, **GitOps** for workloads, **PostgreSQL** for data, **Keycloak** for identity, and **single sign-on into Argo CD** via that identity layer. Everything should be **repeatable from the repo**: another engineer with a clean AWS account can reproduce the same topology using the documented path.

**Tooling note:** Generative AI assistants are **in-scope** for how this gets built; **how they were used** must be recorded (see D1).

---

## 2. Outcomes

| Ref | Outcome |
|-----|---------|
| **G1** | A **live** Kubernetes API on AWS, reachable and usable per the runbook, with **cloud and cluster baseline** expressed entirely in **Terraform or Terragrunt** (no click-ops-only paths). |
| **G2** | **Argo CD** runs in namespace **`argo`**, manages cluster state for **application** delivery, and becomes the **default** way new software lands on the cluster after bootstrap (GitOps). |
| **G3** | **PostgreSQL** in **`database`** and **Keycloak** in **`identity`**; Keycloak **persists to** that Postgres; **Argo CD’s login** is wired to Keycloak (typical pattern: **OIDC**). |
| **G4** | Repository reads as a **handoff-ready package**: modular IaC, operator-facing runbook, explicit design decisions, and an **AI usage appendix**. |

---

## 3. Boundaries

### 3.1 In scope

- End-to-end path: **AWS → cluster → Argo CD → data + IdP → Argo CD auth**.
- Honest treatment of **secrets**, **network exposure**, and **persistence** (even if the answer is “documented manual snapshot” rather than full automation).
- A **repro guide** that does not depend on unstated local state (“works on my laptop”).

### 3.2 Explicitly flexible

- Going **beyond** baseline hardening (e.g. full SOC2 narrative) is optional; if you stay minimal, capture **what would change in a real prod** in D3.

---

## 4. Functional requirements

### FR-1 — Control plane & cloud footprint (AWS + K8s)

| ID | Requirement |
|----|-------------|
| FR-1.1 | Run a **Kubernetes** cluster on **AWS** (managed or self-built is your call—justify it in D3). |
| FR-1.2 | The cluster is **demonstrably operational**: a reviewer following D2 can confirm API access and core expectations you define in the guide. |
| FR-1.3 | **All** supporting **infrastructure** for the cluster and its AWS dependencies is declared in **Terraform or Terragrunt** (no undocumented cloud resources). |

### FR-2 — Delivery layer (Argo CD, GitOps)

| ID | Requirement |
|----|-------------|
| FR-2.1 | Install Argo CD into namespace **`argo`**. |
| FR-2.2 | Argo CD is **authorised** against the cluster and can **reconcile** application definitions you check in. |
| FR-2.3 | After bootstrap, **application workloads** flow through **Argo CD** (sync from Git). Any one-off `kubectl` steps must be **called out** in docs with rationale. |

### FR-3 — Data & identity (Postgres, Keycloak, Argo login)

| ID | Requirement |
|----|-------------|
| FR-3.1 | Run PostgreSQL in namespace **`database`**. |
| FR-3.2 | Storage design reflects **security and durability** intent (at-rest options, backups, sizing/HA—**explain** trade-offs in D3). |
| FR-3.3 | Run Keycloak in namespace **`identity`**. |
| FR-3.4 | Keycloak **uses** the Postgres deployment as its **system database** (not a throwaway in-memory dev default). |
| FR-3.5 | Keycloak is configured for **authentication and authorisation** appropriate to the challenge (realm, clients, roles/groups as needed). |
| FR-3.6 | **Argo CD** is updated so interactive users **authenticate via Keycloak** (OIDC or equivalent is fine; document the flow). |

---

## 5. Repository deliverables

### D1 — Generative AI usage log

- **What** models / IDE agents / skills / scripts were used, and **for which** tasks.
- **Reflection:** speed-ups, dead ends, hallucinations, and anything you would **never** ship without human review in this domain.

### D2 — IaC, manifests, and reproducibility narrative

- Terraform/Terragrunt entrypoints, Helm/Kustomize (if any), and **Argo CD** `Application` / `AppProject` (or `ApplicationSet`) manifests as appropriate.
- Code should be **modular**, **parameterised**, and **legible** to a stranger.
- **Numbered** steps to clone and recreate the environment in an **unfamiliar** AWS account using **only** this repo and public docs you link.
- **Bonus:** compact table of **URLs**, **integration points**, and **credential locations** (placeholders or redaction pattern explained).

### D3 — Decision log & “prod next” notes

For each non-obvious fork in the road:

- **Pressures** that steered the choice (cost, time, security, team skill).
- **Options you ruled out** and why.
- A blunt **“if this were production…”** paragraph (reliability, observability, blast radius, upgrades).

---

## 6. Quality bar (non-functional)

| Lens | Good looks like |
|------|------------------|
| **Reproducibility** | D2 works without private side-channel knowledge. |
| **Judgment** | Network borders, IAM, and dollars signal intentional choices. |
| **Trade-offs** | D3 answers **why**, not only **what**. |
| **Code hygiene** | Small modules, clear names, no mystery `locals` blobs. |
| **AI fluency** | D1 shows you **directed** tools, not the other way around. |
| **Operations** | You can talk about failure, rollback, and **who gets paged**—even if the answer is “we’d add X”. |

---

## 7. How success is demonstrated in-repo

| Reviewer question | Where they look |
|-------------------|-----------------|
| Can I rebuild this? | D2 + Terraform roots + Argo apps |
| Is it wired correctly? | Namespaces, sync paths, OIDC config |
| Do they understand cost/risk? | D3, network diagrams, RBAC |
| Is AI use honest? | D1 |

---

## 8. Review session (typical deep-dives)

Walkthroughs often drill into:

- Module boundaries and dependency direction in Terraform.
- **Blast radius** of a malicious or mistaken Git change that Argo CD applies.
- **When** you’d undo a stack choice (scale, compliance, multi-tenant).
- What you’d measure if a controller or sync job started **eating** cluster capacity.

The expectation is **reasoning**, not trivia about CLI flags.

---

## 9. Hard constraints

| Topic | Rule |
|-------|------|
| Cloud | **AWS** |
| Declarative infra | **Terraform or Terragrunt** for cloud + cluster baseline |
| GitOps | **Argo CD** for ongoing app delivery post-bootstrap |
| Namespaces | **`argo`**, **`database`**, **`identity`** |
| AI | Allowed; must appear in **D1** |

---

## 10. Definition of done

Done means:

1. **FR-1** satisfied with evidence in code + D2.  
2. **FR-2** satisfied: Argo CD in `argo`, GitOps path real.  
3. **FR-3** satisfied: Postgres + Keycloak integrated; Argo CD delegates login to Keycloak.  
4. **D1–D3** present in the repo and consistent with what’s implemented.

---

*Internal requirements document; requirement IDs (FR-*, D*) are stable for tooling and traceability.*
