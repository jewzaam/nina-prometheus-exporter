# nina-prometheus-exporter

[![Build](https://github.com/jewzaam/nina-prometheus-exporter/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/jewzaam/nina-prometheus-exporter/actions/workflows/build.yml)

NINA 3.x plugin that exposes a Prometheus scrape endpoint for equipment state, sequence status, image and autofocus telemetry, guiding RMS, mount position, camera temperature, and more.

## Documentation

See [CLAUDE.md](CLAUDE.md) for the project index — design docs, implementation plan, layout, and dev conventions.

## Install

Either:
1. Install via NINA's in-app plugin manager (once accepted into [nina.plugin.manifests](https://github.com/isbeorn/nina.plugin.manifests)), or
2. Download the latest `NINA.Plugin.PrometheusExporter.<version>.zip` from [Releases](https://github.com/jewzaam/nina-prometheus-exporter/releases) and extract its contents into `%LOCALAPPDATA%\NINA\Plugins\3.0.0\Prometheus Exporter\`.

Releases are built automatically when a `X.Y.Z.0` tag is pushed (see [the versioning spec](docs/superpowers/specs/2026-05-18-versioning.md)). The `manifest.json` attached to each release is the file submitted to the NINA plugin-manifests repo.

## Configure

In NINA → Options → Plugins → Prometheus Exporter:
- **Port** (default `9876`)
- **Bind address** (default `127.0.0.1`, loopback only; set to `0.0.0.0` to expose on every interface, or a specific LAN IP to expose on one)
- **Sequence poll interval (seconds)** (default `1`)
- **Autofocus timeout (minutes)** (default `10`; `0` disables)

Port and Bind changes take effect when you click **Apply** in the Options panel. The status line under the button reflects the actual server state (running, failed, etc.).

The exporter is always on while the plugin is loaded. Uninstall the plugin to stop it.

The HTTP server uses [EmbedIO](https://github.com/unosquare/embedio)'s managed-socket listener (not Windows' `HttpListener`), so binding to any interface — `0.0.0.0`, a specific LAN IP, etc. — works from NINA's normal unprivileged process. No admin / `netsh` setup required.

## Security

The default bind is `127.0.0.1` (loopback), so the endpoint is only reachable from the same machine. To allow Prometheus running on another host to scrape, change Bind address to `0.0.0.0` (or a specific LAN IP) in the plugin Options. There is no authentication — if you expose on the LAN, make sure the network is trusted or restrict access at the firewall.

## License

Apache-2.0. See [LICENSE](LICENSE).
