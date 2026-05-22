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
- **Job `release`** (needs `quality`, push to main only, `contents: write`): extracts `AssemblyVersion`, creates and pushes tag `X.Y.Z.0` if missing, runs `make build-package` + `make build-manifest`, validates the manifest against the upstream JSON schema (via `npx ajv-cli`), then attaches zip + manifest to the GitHub release via `softprops/action-gh-release`. If the tag already exists (no version bump on the commit) the job skips silently.
- **Job `publish-manifest`** (needs `release`, push to main only, only when `released == true`): downloads the manifest from the just-created release, clones the user's fork of `nina.plugin.manifests`, drops the manifest at `manifests/p/Prometheus Exporter/manifest.<version>.json` on a per-version branch, pushes, and opens a PR against `isbeorn/nina.plugin.manifests`. Requires repo secret `PAT` with write access to the fork.

Why one workflow, not two with a tag trigger? GitHub does not re-fire workflows on a tag push made via `GITHUB_TOKEN` (the default workflow token). Inlining tag-creation and release into the same workflow run avoids the re-trigger problem and halves cold-start time.

## Prerequisites for `publish-manifest`

1. Fork `https://github.com/isbeorn/nina.plugin.manifests` to `<owner>/nina.plugin.manifests` (same repo name).
2. Create a Personal Access Token with **write access to the fork** and **pull-requests write** on the upstream repo (classic PAT with `repo` scope, or a fine-grained PAT with those two permissions).
3. Add it as repo secret `PAT` on this repository (Settings → Secrets and variables → Actions).

If `PAT` is missing, the job fails fast with a clear error rather than silently skipping.

## Release flow

1. PR bumps version in `Properties/AssemblyInfo.cs`. `ci.yml` validates format + sources match + bump vs base.
2. Merge to main. `ci.yml`'s `release` job:
   - Creates and pushes tag `X.Y.Z.0` if missing.
   - `make build-package` produces `NINA.Plugin.PrometheusExporter.X.Y.Z.0.zip`.
   - `scripts/build-manifest.ps1` emits `manifest.json` with the GitHub release asset URL + SHA256.
   - Validates `manifest.json` against the upstream schema. Fails the release if invalid.
   - Both files attached to the GitHub release.
3. `publish-manifest` job opens a PR against `isbeorn/nina.plugin.manifests` placing the manifest at `manifests/p/Prometheus Exporter/manifest.<X.Y.Z.0>.json`. Reviewer approves and merges upstream to make the plugin appear in NINA's in-app plugin manager.
