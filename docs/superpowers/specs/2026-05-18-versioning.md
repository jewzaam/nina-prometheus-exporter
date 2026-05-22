# Versioning (NINA plugin deviation from `~/source/standards/common/versioning.md`)

Plugin follows SemVer intent (Major.Minor.Patch increment rules in
`~/source/standards/common/versioning.md` apply unchanged) but the version
*string* and *tag format* diverge because NINA's plugin loader and
plugin-manifest schema impose their own shape.

## Deviations from standard

| Aspect | Standard (`common/versioning.md`) | This project | Why |
|---|---|---|---|
| Version string | `X.Y.Z` | `X.Y.Z.0` (4 segments) | NINA's `PluginLoader` rejects `AssemblyFileVersion` with `< 4` components (treated as revision `-1` and skipped). See `Properties/AssemblyInfo.cs` and `project_nina_plugin_gotchas` memory. |
| Source of truth | `pyproject.toml` + `__version__` | `Properties/AssemblyInfo.cs` (`AssemblyVersion` + `AssemblyFileVersion` — both must match) | C# project, not Python. The plugin-manifests schema reads `AssemblyFileVersion` via PE metadata. |
| Tag format | `vX.Y.Z` | `X.Y.Z.0` (no `v` prefix, 4 segments) | Matches the canonical NINA plugin release sample (`tools/github-action.yaml` in `nina.plugin.manifests`) which triggers on tag regex `[0-9]+.[0-9]+.[0-9]+.[0-9]+`. The same sample stores the manifest at `manifests/<letter>/<Plugin Name>/manifest.<X.Y.Z.B>.json` — file name carries the version, no separate version subdirectory. |
| Auto-tag on push to main | Separate `version-check.yml` | Bundled into `ci.yml`'s `release` job | Workflow consolidation: GitHub does not re-fire workflows on tags pushed by `GITHUB_TOKEN`, so the tag-trigger pattern from the standard would never run our release. Inlining tag + build + release into one workflow run also halves the CI cold-start cost on main pushes. |
| `make version-check` Makefile target | Yes (`version-check.mk`, Python-targeted) | Reimplemented as `scripts/version-check.ps1` | Pure PowerShell; no Python dep. Target name matches the standards target. |

## What `make version-check` validates

1. **Format** — `AssemblyVersion` matches `^[0-9]+\.[0-9]+\.[0-9]+\.0$` (Build segment fixed at `0`; revision bumps would imply a different release cadence we don't use).
2. **Sources match** — `AssemblyVersion` equals `AssemblyFileVersion`.
3. **Bumped from main** — when `BASE_REF` is set (CI on PR), version differs from `origin/$BASE_REF`. Skipped locally / on push.

## Workflow

Single workflow: **`ci.yml`** — triggers on PR + push to main.

- **Job `quality`** (always runs): `make restore RESTORE_FLAGS=--locked-mode` then `make check`. `make check` includes build-release, test-unit, test-format, test-reachability, and version-check. For PRs the job sets `BASE_REF=${{ github.base_ref }}` so `make version-check` enforces the bump.
- **Job `release`** (needs `quality`, push to main only, `contents: write`): extracts `AssemblyVersion`, creates and pushes tag `X.Y.Z.0` if missing, runs `make build-package` + `make build-manifest`, validates the manifest against the upstream JSON schema (via `make test-manifest`), then attaches zip + manifest to the GitHub release via `softprops/action-gh-release`. If the tag already exists (no version bump on the commit) the job skips silently.

Manifest submission to `isbeorn/nina.plugin.manifests` is **not** a CI job. It's a local Make target — see [Manifest submission](#manifest-submission) below. Reason: opening a cross-repo PR from CI requires either a classic PAT (account-wide blast radius) or a fine-grained PAT that can grant write on the upstream repo you don't own. Local orchestration via `gh` CLI uses your existing user auth, scoped to your normal session.

Why one workflow, not two with a tag trigger? GitHub does not re-fire workflows on a tag push made via `GITHUB_TOKEN` (the default workflow token). Inlining tag-creation and release into the same workflow run avoids the re-trigger problem and halves cold-start time.

## Manifest submission

After a release lands on GitHub, run `make publish-manifest` from your workstation. The target (`scripts/publish-manifest.ps1`) does the following:

1. Reads the version from `Properties/AssemblyInfo.cs`.
2. Downloads `manifest.json` from the matching GitHub release (`gh release download <ver>`).
3. Re-validates it against the upstream schema (`make test-manifest`).
4. `cd`s into `$MANIFESTS_REPO_DIR` (defaults to `~/source/nina.plugin.manifests`), verifies a clean tree, syncs `main` with the `upstream` remote.
5. Creates branch `prometheus-exporter/<X.Y.Z.0>` (reuses with `-B` on re-run).
6. Copies the manifest to `manifests/p/Prometheus Exporter/manifest.<X.Y.Z.0>.json`.
7. Commits, force-pushes the branch to your fork (`origin`).
8. Opens (or updates) a PR against `isbeorn/nina.plugin.manifests:main` via `gh pr create`.

Prereqs (one-time):

- `~/source/nina.plugin.manifests` is a clone of `<owner>/nina.plugin.manifests` (your fork) with:
  - `origin` → your fork
  - `upstream` → `https://github.com/isbeorn/nina.plugin.manifests`
- `gh` CLI authenticated as the fork owner.
- `npx` + Node on PATH (for `test-manifest`).

Override `$MANIFESTS_REPO_DIR` if your local clone lives elsewhere.

## Release flow

1. PR bumps version in `Properties/AssemblyInfo.cs`. `ci.yml` validates format + sources match + bump vs base.
2. Merge to main. `ci.yml`'s `release` job:
   - Creates and pushes tag `X.Y.Z.0` if missing.
   - `make build-package` produces `NINA.Plugin.PrometheusExporter.X.Y.Z.0.zip`.
   - `scripts/build-manifest.ps1` emits `manifest.json` with the GitHub release asset URL + SHA256.
   - Validates `manifest.json` against the upstream schema. Fails the release if invalid.
   - Both files attached to the GitHub release.
3. Locally: run `make publish-manifest`. PR appears upstream. Reviewer approves and merges to make the plugin appear in NINA's in-app plugin manager.
