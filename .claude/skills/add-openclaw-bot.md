---
name: add-openclaw-bot
description: >
  Guides the creation of a new openclaw bot instance with all necessary configuration files.
  Asks one question at a time to fully populate every workspace file.
trigger: >
  Use this skill when the user asks to add a new bot, create a new bot instance, spin up
  a new bot, deploy another openclaw bot, or any similar phrasing.
---

# Add Openclaw Bot

You are creating a new bot instance under `manifests/openclaw/<name>/`. The Helm chart at
`charts/openclaw/` handles all templating — you only need to generate the per-bot files.
Ask every question below **one at a time** — do not batch questions. Wait for the answer
before proceeding to the next. At the end, generate all files.

---

## Questions

### Section 1 — Identity & Personality

**Q1.** What is the bot's short name?
- This becomes the directory name (`manifests/openclaw/<name>/`), the `botName` value,
  and the prefix for all Kubernetes resource names (e.g., `dev-openclaw`, `dev-openclaw-workspace`).
- Use lowercase, hyphens only (e.g., `dev`, `staging`, `ops-assistant`).

**Q2.** What is the bot's display name, emoji, and role?
- Display name: shown in messages and identity (e.g., "Openclaw Dev")
- Emoji: personality emoji (e.g., 🦞, 🤖, 🔧)
- Role: one-line description of what this bot does (e.g., "Development Cluster Assistant")
- These populate `IDENTITY.md`.

**Q3.** Describe the bot's personality.
- How does it communicate? What is its tone (terse, verbose, casual, formal)?
- Does it use humor? Any themed references?
- How does it make decisions — cautious, autonomous, by-the-book?
- When does it stay serious vs. lighten the mood?
- This populates `SOUL.md`. Be as descriptive as you want — more detail = better behavior.

---

### Section 2 — Purpose & Scope

**Q4.** What is this bot's primary mission?
- What problem does it solve or what role does it fill in the cluster?
- Example: "Monitor the dev namespace for failing pods and auto-restart them",
  "Manage the CI/CD pipeline namespace", "Act as a read-only observability assistant"
- This becomes the overview section of `AGENTS.md`.

**Q5.** What namespaces, applications, or resources does this bot manage or monitor?
- List namespaces (e.g., `dev`, `staging`, `monitoring`)
- List ArgoCD applications if applicable
- List specific workloads if relevant
- This defines the scope section of `AGENTS.md`.

**Q6.** Describe the bot's main operational loop.
- What does it check, how often (cron schedule or frequency)?
- What does it do when it finds an issue — alert, auto-remediate, open a PR?
- What is the deduplication window (default: 4 hours)?
- This populates the procedures section of `AGENTS.md` and `openclaw.json` cron config.

**Q7.** What actions require explicit human approval before execution?
- Which operations are auto-approved (read-only, safe restarts)?
- Which always require Telegram confirmation?
- Are there any actions this bot is completely prohibited from taking?
- This populates the approval model in `AGENTS.md` and core principles in `SOUL.md`.

**Q8.** What are the error handling and escalation rules?
- How many retries before escalating?
- Who gets notified on failure?
- Are there any silent-failure modes or actions to take when the bot cannot reach Telegram?
- This populates the error handling section of `AGENTS.md`.

---

### Section 3 — Human Operator

**Q9.** Who operates this bot?
- Describe them: role, technical level, how they prefer to receive updates
  (brief/detailed, structured/conversational).
- What language do they prefer?
- How do they typically interact with the bot — brief approvals, detailed instructions, emojis?
- This populates `USER.md`.

**Q10.** What is the operator's Telegram chat ID and bot username?
- Chat ID (numeric, e.g., `8542985250`) — goes into `openclaw.json` `allowFrom` and `USER.md`.
- Bot username (e.g., `@mybot`) — goes into `USER.md`.

---

### Section 4 — Tools & Capabilities

**Q11.** Which tools does this bot need?
Select all that apply:
- `kubectl` — Kubernetes cluster operations
- `git` — GitOps workflow (requires SSH, see Q12)
- `helm` — Helm release management
- `argocd` — ArgoCD app management (requires ArgoCD init container, see Q13)
- `kubeseal` — Sealed secrets management
- `calicoctl` — Calico network policy
- `ansible-lint` — Ansible validation (no playbook execution)
- `pre-commit` — Pre-commit hook validation

This populates `TOOLS.md`. For each selected tool, you will be asked for cluster-specific
flags or usage patterns in the next question.

**Q12.** For each selected tool: are there cluster-specific flags, endpoints, server URLs,
or usage patterns to document?
- Example: specific kubeconfig paths, custom ArgoCD server URL, non-standard namespaces,
  repo-specific git remotes, helm repo aliases
- Answer per tool, or say "defaults" to use the standard patterns from the main bot.

**Q13.** Does this bot need git over SSH?
- Yes → sets `git.sshEnabled: true` in `values.yaml`, adds `GIT_SSH_COMMAND` env var to the deployment.
- No → skip.
- If yes: what is the git remote URL and working directory for the main repo?

**Q14.** Does this bot need ArgoCD access?
- Yes → sets `initContainers.argocd.enabled: true` in `values.yaml`, adds `init-argocd`
  init container that pre-authenticates before the main container starts.
- No → skip.
- If yes: what is the ArgoCD server URL (e.g., `argocd-server.argocd.svc.cflor.org`)?

---

### Section 5 — Model & API

**Q15.** Which AI model should this bot use?
- Default: `google/gemini-2.5-flash` (no override needed in values.yaml)
- Override if needed — goes into `openclaw.json` agents.defaults.model.primary.

**Q16.** Gemini API key:
- Provide the value now (will be used for sealing), OR
- Confirm you will seal it manually after file generation.

---

### Section 6 — Telegram Channel

**Q17.** Telegram bot token:
- Provide the value now (will be used for sealing), OR
- Confirm you will seal it manually after file generation.

**Q18.** DM policy for the Telegram channel:
- `allowlist` — only users listed in `allowFrom` can DM the bot (recommended)
- `open` — any user can interact

**Q19.** List of allowed Telegram user IDs (for `allowFrom` in `openclaw.json`).
- Numeric IDs, comma-separated (e.g., `8542985250, 1234567890`)

---

### Section 7 — Infrastructure Overrides

**Q20.** Override the default container image?
- Default: `ghcr.io/carlosgit2016/openclaw:latest` (no override needed)
- Provide `image.repository` and/or `image.tag` values to override.

**Q21.** Override the default PVC sizes?
- Default: `1Gi` request / `10Gi` limit (no override needed)
- Provide `pvc.storageRequest` and/or `pvc.storageLimit` values to override.

**Q22.** Override the default cluster role?
- Default: `cluster-admin` (no override needed)
- Provide a `clusterRole` value if this bot should have reduced privileges.

---

## File Generation

Once all questions are answered, generate the following files.

### `manifests/openclaw/<name>/values.yaml`

Only include values that differ from the chart defaults (`charts/openclaw/values.yaml`).
At minimum, `botName` is always required.

```yaml
botName: <name>

# Include only if Q14 = yes:
initContainers:
  argocd:
    enabled: true
    server: <argocd-server-url>

# Include only if Q13 = yes:
git:
  sshEnabled: true

# Include only if Q15 is non-default:
# (add to configmap openclaw.json instead — values.yaml doesn't control model)

# Include only if Q20 overrides image:
# image:
#   repository: <repo>
#   tag: <tag>

# Include only if Q21 overrides PVC:
# pvc:
#   storageRequest: <value>
#   storageLimit: <value>

# Include only if Q22 overrides cluster role:
# clusterRole: <role>
```

### `manifests/openclaw/<name>/configmap.yaml`

Hardcode the prefixed name — Helm provides the resource reference via `configMapName` value
(or derives it automatically from `botName`). Add sync-wave annotation.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: <name>-openclaw-config
  namespace: openclaw
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
data:
  openclaw.json: |
    { ... }   # from Q10, Q15, Q18, Q19, Q6
  IDENTITY.md: |
    ...       # from Q2, Q3
  SOUL.md: |
    ...       # from Q3, Q4, Q7
  TOOLS.md: |
    ...       # from Q11, Q12
  USER.md: |
    ...       # from Q9, Q10
  AGENTS.md: |
    ...       # from Q4, Q5, Q6, Q7, Q8
              # Self-preservation section: use <name>-openclaw-* resource names
```

### `manifests/openclaw/<name>/sealed-secret.yaml`

Always include `<name>-openclaw-secrets`. Include `<name>-openclaw-ssh-key` only if Q13 = yes.
Both resources need `argocd.argoproj.io/sync-wave: "-1"` so they exist before the Deployment.

If the user provided values in Q16/Q17, provide the exact kubeseal commands:

```bash
kubectl create secret generic <name>-openclaw-secrets -n openclaw \
  --from-literal=GEMINI_API_KEY="<value>" \
  --from-literal=TELEGRAM_BOT_TOKEN="<value>" \
  --from-literal=TELEGRAM_CHAT_ID="<value>" \
  --dry-run=client -o yaml | kubeseal --format yaml \
  > manifests/openclaw/<name>/sealed-secret.yaml

# Only if git.sshEnabled = true:
kubectl create secret generic <name>-openclaw-ssh-key -n openclaw \
  --from-file=id_rsa=<path-to-key> \
  --dry-run=client -o yaml | kubeseal --format yaml \
  >> manifests/openclaw/<name>/sealed-secret.yaml
```

After sealing, add to each SealedSecret's metadata:
```yaml
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
```

If they chose manual sealing, output placeholder file with the commands above.

### `manifests/applications/<name>.application.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <name>
  namespace: argocd
spec:
  project: default
  sources:
    - repoURL: https://github.com/carlosgit2016/homelab.git
      targetRevision: HEAD
      path: charts/openclaw
      helm:
        valueFiles:
          - $values/manifests/openclaw/<name>/values.yaml
    - repoURL: https://github.com/carlosgit2016/homelab.git
      targetRevision: HEAD
      ref: values
    - repoURL: https://github.com/carlosgit2016/homelab.git
      targetRevision: HEAD
      path: manifests/openclaw/<name>
      directory:
        include: '{configmap.yaml,sealed-secret.yaml}'
  destination:
    server: https://kubernetes.default.svc
    namespace: openclaw
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## Post-Generation Checklist

After generating files, remind the user:

1. **Seal secrets** using the kubeseal commands above (requires cluster access).
2. **Verify Helm rendering**: `helm template <name> charts/openclaw -f manifests/openclaw/<name>/values.yaml`
3. **Run pre-commit**: `pre-commit run --all-files` to validate YAML.
4. **Commit and push** — ArgoCD will pick up `manifests/applications/<name>.application.yaml`
   via the root app pattern and sync automatically.
