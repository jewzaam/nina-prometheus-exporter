# nina-prometheus-exporter

NINA 3.x plugin exposing a Prometheus scrape endpoint. C# / .NET 8 / WPF.

## Documentation

- [README](README.md) — install, configure, security
- [CHANGELOG](CHANGELOG.md) — release history
- [Design spec (this implementation)](docs/superpowers/specs/2026-05-15-nina-prometheus-plugin-design.md) — how the plugin is built (companion to the original problem-statement spec)
- [Implementation plan](docs/superpowers/plans/2026-05-15-nina-prometheus-plugin.md) — task-by-task plan that produced the v0.1 implementation
- [Original problem-statement spec](nina-prometheus-plugin-spec.md) — what we set out to expose, sourced from the existing log-exporter setup
- [Coding-standards research prompt](docs/research-prompt-coding-standards.md) — prompt to feed `cited-research` for a standalone NINA-plugin standards doc

## Build / test / install

```
make help                    # list targets
make check                   # default: test-env + build-release + test-unit + test-format
make install                 # build Release, copy DLLs to %LOCALAPPDATA%\NINA\Plugins\3.0.0\Prometheus Exporter\
make install-dev-nina        # kill NINA, install, relaunch (dev loop)
make build-package           # zip the ship-list DLLs for GitHub release
```

## Layout

- `Properties/AssemblyInfo.cs` — plugin manifest metadata read by NINA's PluginLoader
- `PrometheusExporterPlugin.cs` — MEF entry point, lifecycle, wiring
- `PrometheusExporterOptions.cs` — `IPluginOptionsAccessor`-backed view-model + Apply command
- `PrometheusServer.cs` — EmbedIO `HttpListenerMode.EmbedIO` HTTP transport
- `MetricFactory.cs` — default-label helper (profile_name, host_name)
- `Constants.cs` — option defaults, label keys, equipment-type values
- `Options.xaml(.cs)` — Options panel `DataTemplate`
- `Stream/*.cs` — one collector per metric family (camera, mount, focuser, ..., autofocus state machine, JSON parser)
- `tests/` — xUnit + Moq
- `scripts/` — PowerShell helpers (install, uninstall, run-nina, kill-nina, build-package, ship-list, select-ship-dlls, test-env)
- `Makefile` — verb-[qualifier-]noun grammar; entry point for local + CI

## Conventions

- Personal coding standards live at `~/source/standards/`. Audit with `/jewzaam-reviews:standards`. Apply with `/jewzaam-reviews:apply-review`.
- Commits use Conventional Commits + an `Assisted-by: Claude Code (<model>)` footer.
- Single ship list in `scripts/ship-list.ps1`; both install and build-package read it. NINA framework DLLs are kept out of `bin/Release` via `PrivateAssets=all` on the `NINA.Plugin` reference.
