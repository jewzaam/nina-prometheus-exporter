# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release.
- `/metrics` endpoint on `http://0.0.0.0:9876` (configurable), served via EmbedIO (no `netsh urlacl` required for LAN binds).
- Equipment connection gauges: `nina_equipment{type=...}` for camera, mount, focuser, filterwheel, guider, dome, rotator, flat_device, safety_monitor, weather, switch.
- Sequence status: `nina_status{category,item}` gauge + `nina_status_count_started_total` / `nina_status_count_completed_total` counters, driven by a 1-second poll of running items.
- Per-exposure metrics from `ImageSaved`: `nina_exposure_total{exposure_time_s,filter,gain,offset,binning}`, `nina_detect_hfr`, `nina_detect_stars`, `nina_detect_rms_arcsec`, `nina_detect_camera_temperature_celsius`, `nina_image_{mean,median,stdev,mad,min_adu,max_adu,hfr_stdev}`.
- Autofocus: `nina_autofocus_running`, `nina_autofocus_success_total{filter}`, `nina_autofocus_failure_total{reason}`, plus JSON-report-driven `nina_autofocus_rsquares`, `nina_autofocus_final_hfr`, `nina_autofocus_duration_seconds`, `nina_autofocus_{initial,calculated}_position`, `nina_autofocus_{initial,calculated}_hfr`. Configurable timeout heuristic detects hung AF runs.
- Mount: `nina_mount_{altitude_degrees,azimuth_degrees,ra_hours,dec_degrees,side_of_pier,tracking,slewing,parked,meridian_flip}` + edge counter `nina_mount_side_of_pier_unknown_total`.
- Focuser: `nina_focuser_position`, `nina_focuser_temperature_celsius`.
- Filter wheel: `nina_filter_position`, `nina_filter_current{filter_name}`.
- Guider: `nina_guider_{guiding,rms_{ra,dec,total}_arcsec,peak_{ra,dec}_arcsec,step_{ra,dec}_{distance,duration_ms}}` + `nina_guider_dithers_total`.
- Camera: `nina_camera_temperature_celsius`, `nina_camera_cooler_power_percent`, `nina_camera_download_timeout_total`.
- Optional devices: `nina_dome_*`, `nina_rotator_*`, `nina_flat_*`, `nina_safety_is_safe`, `nina_weather_*`.
- Default labels `profile_name` and `host_name` on every metric.
- Options UI: port, bind address, sequence poll interval (seconds), autofocus timeout (minutes). Port/bind/poll-interval changes apply live; no NINA restart required.
