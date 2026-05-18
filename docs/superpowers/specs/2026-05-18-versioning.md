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
| Tag format | `vX.Y.Z` | `X.Y.Z.0` (no `v` prefix, 4 segments) | Matches the canonical NINA plugin release sample (`tools/github-action.yaml` in `nina.plugin.manifests`) which triggers on tag regex `[0-9]+.[0-9]+.[0-9]+.[0-9]+`. Aligns with manifest path `manifests/<l>/<plugin>/<X.Y.Z[.B]>/manifest.json`. |
| Auto-tag on push to main | Yes (`version-check.yml`) | Yes (adapted) | Standard pattern, just reads version out of `AssemblyInfo.cs` instead of `pyproject.toml`. |
| `make version-check` Makefile target | Yes (`version-check.mk`, Python-targeted) | Replaced with `make test-version` calling `scripts/test-version.ps1` | Pure PowerShell; no Python dep. Verb-noun grammar (`test-` prefix for read-only checks) matches the rest of the Makefile. |

## What `make test-version` validates

1. **Format** — `AssemblyVersion` matches `^[0-9]+\.[0-9]+\.[0-9]+\.0$` (Build segment fixed at `0`; revision bumps would imply a different release cadence we don't use).
2. **Sources match** — `AssemblyVersion` equals `AssemblyFileVersion`.
3. **Bumped from main** — when `BASE_REF` is set (CI on PR), version differs from `origin/$BASE_REF`. Skipped locally / on push.

## Workflow split

- **`test-version.yml`** — read-only. PR only. Runs `make test-version` with `BASE_REF=<base>` to enforce format, source-pair match, and bump-vs-base. No write permissions.
- **`release.yml`** — owns all side effects. Triggers on push to `main` and on tag push `X.Y.Z.0`.
  - Always-run `validate` job: `make test-version` (no bump check since not a PR).
  - On push to `main`: `auto-tag` job creates and pushes `X.Y.Z.0` if missing. The tag push then re-fires `release.yml`.
  - On tag push: `release` job re-verifies the tag matches `AssemblyVersion`, builds, zips, generates `manifest.json`, attaches both to a GitHub release.

## Release flow

1. PR bumps version in `Properties/AssemblyInfo.cs`. `test-version.yml` validates format + bump.
2. Merge to main. `release.yml`'s `auto-tag` job creates and pushes `X.Y.Z.0` if missing.
3. Tag push re-fires `release.yml`:
   - `make build-release`
   - `make build-package` produces `NINA.Plugin.PrometheusExporter.X.Y.Z.0.zip` (filename matches NINA sample so `appendVersionToArchive` semantics carry over for anyone forking).
   - `scripts/build-manifest.ps1` emits `manifest.json` with the GitHub release asset URL + SHA256.
   - Both files attached to the GitHub release.
4. Out-of-band: submit `manifest.json` to `https://github.com/isbeorn/nina.plugin.manifests` at path `manifests/p/Prometheus Exporter/<version>/manifest.json` for the in-app plugin manager listing.
