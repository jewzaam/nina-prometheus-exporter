# NINA Prometheus Exporter

NINA 3.x plugin that exposes a Prometheus scrape endpoint for equipment state, sequence status, image and autofocus telemetry, guiding RMS, mount position, camera temperature, and more.

## Install

Either:
1. Install via NINA's in-app plugin manager (once published), or
2. Download the latest `.zip` from [Releases](https://github.com/jewzaam/nina-prometheus-exporter/releases) and extract its contents into `%LOCALAPPDATA%\NINA\Plugins\3.0.0\Prometheus Exporter\`.

## Configure

In NINA → Options → Plugins → Prometheus Exporter:
- **Port** (default `9876`)
- **Bind address** (default `0.0.0.0`; loopback `127.0.0.1` keeps it local-only)
- **Sequence poll interval (seconds)** (default `1`)
- **Autofocus timeout (minutes)** (default `10`; `0` disables)

The exporter is always on while the plugin is loaded. Uninstall the plugin to stop it.

The HTTP server uses [EmbedIO](https://github.com/unosquare/embedio)'s managed-socket listener (not Windows' `HttpListener`), so binding to any interface — `0.0.0.0`, a specific LAN IP, etc. — works from NINA's normal unprivileged process. No admin / `netsh` setup required.

## Security

The default `0.0.0.0` bind exposes the metrics endpoint on every network interface. There is no authentication. If your NINA host is not on a trusted LAN, change the bind to `127.0.0.1` or use a host firewall to restrict access.

## License

Apache-2.0. See [LICENSE](LICENSE).
