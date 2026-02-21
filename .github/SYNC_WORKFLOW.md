# sync-to-public.yml: Automated Release Synchronization

**Purpose**: Synchronize clean, production-ready code from the private `yaml-dev` repo to the public `jpazvd/yaml` repo when a release is tagged.

**Status**: Production-ready
**Maintainer**: Jo&atilde;o Pedro Azevedo

---

## How It Works

### Trigger

The workflow activates when a **version tag** is pushed:

```bash
git tag -a v1.9.0 -m "Release v1.9.0"
git push origin v1.9.0    # ← Triggers sync workflow
```

It can also be triggered manually via **Actions > workflow_dispatch**.

### Execution

1. **Checkout** full history
2. **Whitelist copy** into a staging directory (only public content)
3. **Sanitize** — remove `.log` files, `_archive` dirs, files >5MB
4. **Verify** — fail if any private content leaked into staging
5. **Push** to `jpazvd/yaml` `staging` branch
6. **Push tags** to public repo

### After Sync

Content lands on the `staging` branch of `jpazvd/yaml`. You must:

1. Open a PR from `staging` → `main`
2. Review the diff to confirm no private content
3. Merge the PR

---

## Whitelist (what gets synced)

### Folders

| Folder | What | Exclusions |
| ------ | ---- | ---------- |
| `src/` | Core package (ado, sthlp, pkg, toc) | None |
| `qa/` | QA scripts and fixtures | `logs/`, `legacy/`, `scripts/debug/`, `_wbopendata_indicators.yaml` (18MB) |
| `examples/` | Usage examples and sample data | `logs/`, `yaml_sj_article_examples*` |
| `scripts/` | Benchmark scripts | None |

### Root files

`README.md`, `readme.txt`, `.gitignore`, `LICENSE`, `CHANGELOG.md`

### Never synced

| Item | Reason |
| ---- | ------ |
| `paper/` | Unpublished article (LaTeX, PDFs) |
| `internal/` | Internal development plans |
| `doc/` | Sync status, revision guides, architecture plans |
| `*.log` | Debug and test execution logs |
| `.github/workflows/sync-to-public.yml` | The sync workflow itself |

---

## Setup: Deploy Key

The workflow requires an SSH deploy key stored as `PUBLIC_REPO_DEPLOY_KEY`.

### One-time setup

1. Generate a key pair:
   ```bash
   ssh-keygen -t ed25519 -C "yaml-dev-sync" -f yaml_deploy_key -N ""
   ```

2. Add the **public** key to `jpazvd/yaml`:
   - Settings > Deploy keys > Add deploy key
   - Title: `yaml-dev sync`
   - Key: contents of `yaml_deploy_key.pub`
   - Check **Allow write access**

3. Add the **private** key to `jpazvd/yaml-dev`:
   - Settings > Secrets and variables > Actions > New repository secret
   - Name: `PUBLIC_REPO_DEPLOY_KEY`
   - Value: contents of `yaml_deploy_key`

4. Delete the local key files:
   ```bash
   rm yaml_deploy_key yaml_deploy_key.pub
   ```

---

## Quick Reference

```bash
# Tag and sync
git tag -a v1.9.0 -m "Release v1.9.0"
git push origin v1.9.0

# Manual trigger (GitHub UI)
# Actions > Sync to Public Repo > Run workflow

# After sync: create PR on jpazvd/yaml
# staging → main
```
