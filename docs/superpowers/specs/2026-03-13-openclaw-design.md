# Openclaw — Cluster Administrator AI Agent
**Date:** 2026-03-13
**Status:** DESIGN COMPLETE

---

## What This Is

Openclaw is an autonomous AI agent deployed directly inside the Kubernetes homelab cluster. It acts as the cluster's administrator, watching application health and a Trello board for tasks, then reasoning about issues and executing changes (with Human God approval via Telegram) while keeping the GitOps repo in sync via PRs.

---

## Context

- **Cluster:** 3-node Kubernetes homelab (phoenix/yamato/defcom) on Proxmox, managed via GitOps (ArgoCD → `carlosgit2016/homelab` on GitHub)
- **Existing apps:** nginx, longhorn, metrics-server, kube-prometheus, jackett, qBittorrent, radarr, ArgoCD
- **GitOps pattern:** `manifests/applications/*.application.yaml` → ArgoCD auto-syncs on push to `main`
- **RBAC pattern:** `manifests/rbac/` — ClusterRoleBindings managed as manifests

---

## Decisions Made

| Decision | Choice | Rationale |
|---|---|---|
| Deployment model | Kubernetes Deployment in cluster (Option A) | Self-contained, ArgoCD-managed, lives with the cluster |
| AI model | Gemini via API key | Easy to swap — model/key stored in Kubernetes Secret |
| Trello integration | Poll every 5 minutes | No public ingress needed |
| GitHub auth | Personal Access Token (PAT) as Kubernetes Secret | Simple, sufficient for homelab |
| Human approval gate | Telegram — every action requires approval before execution | Safety first |
| Test gate | `pre-commit` + `ansible-lint` + `kubectl apply --dry-run=server` | Matches existing repo validation |
| Repo workflow | Ephemeral clone → change → test → PR + direct apply after approval | Audit trail via PR, immediate effect via apply |
| PR purpose | Audit trail + keep GitOps source of truth in sync | Not a blocking gate — Human God already approved via Telegram |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Kubernetes Cluster                                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  namespace: openclaw                                  │   │
│  │                                                       │   │
│  │  ┌─────────────────────────────────────────────┐     │   │
│  │  │  Deployment: openclaw                        │     │   │
│  │  │  ServiceAccount → ClusterRoleBinding         │     │   │
│  │  │    (cluster-admin)                           │     │   │
│  │  │                                              │     │   │
│  │  │  Containers:                                 │     │   │
│  │  │    - openclaw (custom image)                 │     │   │
│  │  │      + kubectl, git, ansible, terraform      │     │   │
│  │  │      + openclaw runtime (Node ≥22)           │     │   │
│  │  │                                              │     │   │
│  │  │  Volumes:                                    │     │   │
│  │  │    - emptyDir: /workspace (ephemeral clones) │     │   │
│  │  │    - ConfigMap: openclaw skills + config     │     │   │
│  │  │    - Secret: Gemini key, GitHub PAT,         │     │   │
│  │  │              Telegram token, Trello key      │     │   │
│  │  └─────────────────────────────────────────────┘     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
    Trello API           Telegram API         GitHub API
  (poll every 5m)     (notify + approval)   (clone + PR)
         │
         ▼
    Gemini API (reasoning)
```

**Key architectural points:**
- OpenClaw runs headlessly — Gateway daemon started via entrypoint in the container
- All secrets injected as env vars from a Kubernetes `Secret`
- Model is swappable — change one Secret key to move from Gemini → Claude → OpenAI
- ArgoCD manages openclaw itself via `manifests/applications/openclaw.application.yaml`

---

## Agent Loop

### Loop 1 — Cluster Health Watcher (every 5 minutes)

```
1. kubectl get pods --all-namespaces → find non-Running/non-Completed pods
2. kubectl get nodes → check node conditions
3. ArgoCD app health → check sync/health status via argocd CLI or API
4. If issues found:
   → gather context (describe pod, logs, events)
   → reason about root cause (Gemini)
   → send Telegram message to Human God:
       "🚨 Issue detected: <app> in <namespace>
        Cause: <diagnosis>
        Proposed action: <what openclaw wants to do>
        Reply ✅ to approve or ❌ to skip"
   → wait for Telegram reply
   → if approved: execute action → report result → update code → open PR
```

### Loop 2 — Trello Task Poller (every 5 minutes)

```
1. Fetch cards from "To Do" list in configured board
2. For each new card (not yet processed):
   → read card title + description
   → reason about required action (Gemini)
   → send Telegram: "📋 New task: <title>\nPlan: <what openclaw wants to do>\n✅ approve ❌ skip"
   → wait for Telegram reply
   → if approved: execute → report result → update code → open PR
   → move Trello card to "Done"
```

### Execution Engine (shared by both loops)

```
Any approved action goes through:
  1. Clone repo to /workspace (ephemeral)
  2. Make changes
  3. Run: pre-commit run --all-files
         ansible-lint (if ansible files changed)
         kubectl apply --dry-run=server (if manifests changed)
  4. If tests pass → git push branch → open PR via GitHub API
  5. kubectl / ansible / terraform apply (actual execution)
  6. Report result to Telegram
  7. Cleanup /workspace
```

### OpenClaw Skills (loaded via ConfigMap)

| Skill file | Purpose |
|---|---|
| `cluster-health.md` | How to inspect cluster state (pods, nodes, ArgoCD) |
| `trello-poller.md` | How to poll and process Trello cards |
| `telegram-approval.md` | Approval request/response protocol with Human God |
| `git-pr-workflow.md` | Clone → change → test → PR pattern |
| `execution-engine.md` | How to run kubectl / ansible / terraform safely |

---

## Secrets & Configuration

All sensitive values stored in a Kubernetes `Secret` in the `openclaw` namespace:

| Key | Purpose |
|---|---|
| `GEMINI_API_KEY` | Gemini model authentication |
| `OPENCLAW_MODEL` | Model identifier (e.g. `google/gemini-2.0-flash`) — change to swap models |
| `GITHUB_PAT` | GitHub Personal Access Token for cloning + PR creation |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token for Human God communication |
| `TELEGRAM_CHAT_ID` | Human God's Telegram chat ID |
| `TRELLO_API_KEY` | Trello API key |
| `TRELLO_TOKEN` | Trello OAuth token |
| `TRELLO_BOARD_ID` | Target Trello board ID |
| `TRELLO_LIST_ID` | "To Do" list ID within the board |

> Secrets are stored in `.env` at the repo root (gitignored). Use values from `.env` to generate SealedSecret manifests with `kubeseal`. See `manifests/openclaw/sealed-secret.yaml` for the bootstrap commands.

---

## Kubernetes Manifests (to be created)

```
manifests/
└── openclaw/
    ├── namespace.yaml
    ├── serviceaccount.yaml
    ├── clusterrolebinding.yaml        # cluster-admin binding
    ├── secret.yaml                    # placeholder (real values not committed)
    ├── configmap-skills.yaml          # openclaw skill files
    ├── configmap-config.yaml          # openclaw.json config
    └── deployment.yaml
manifests/applications/
└── openclaw.application.yaml         # ArgoCD Application CRD
```

---

## Custom Docker Image

Base: `node:22-slim`

Additional tooling installed:
- `kubectl` (matching cluster version 1.31)
- `git`
- `ansible` + `ansible-lint`
- `terraform`
- `pre-commit`
- `openclaw` CLI (npm global install)

Image to be built and pushed to a container registry (e.g. GHCR).

---

## Resolved Design Decisions

| Item | Decision |
|---|---|
| Telegram interaction | Native openclaw channel. `dmPolicy: allowlist`, `allowFrom: [8542985250]`. No custom code needed. |
| Agent behavior | Bootstrap `.md` files (AGENTS.md, SOUL.md, TOOLS.md, IDENTITY.md, USER.md) mounted from ConfigMap. No application code. |
| Deduplication | Agent tracks seen issues in `/workspace/seen-issues.json` (PVC-backed). Re-alerts after 4 hours. |
| Error handling | Test gate failures reported to Telegram, action aborted, workspace cleaned. No retry. |
| Image registry | `ghcr.io/carlosgit2016/openclaw:latest` built via GitHub Actions on push to `main`. |
| Secret management | Sealed Secrets (bitnami-labs). Values sourced from `.env` at repo root (gitignored). |
| Node affinity | None. |
| Runtime | `ghcr.io/openclaw/openclaw:latest` — no custom application code. |
| Trello integration | Deferred — see `docs/superpowers/specs/trello-integration.md`. |

---

## Open Questions

All open questions resolved. See Resolved Design Decisions above.
