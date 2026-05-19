# NINA Prometheus Exporter — Makefile
# Verb-[qualifier-]noun grammar per ~/source/standards/build/makefile.md
# Whitelisted bare verbs: help, check, clean, format, install, uninstall, run

PROJECT          ?= NINA.Plugin.PrometheusExporter
TEST_PROJECT     ?= tests/NINA.Plugin.PrometheusExporter.Tests.csproj
# Resolve dotnet from PATH (per standards/build/makefile.md "no hardcoded paths").
# Override with `make DOTNET=/full/path/to/dotnet.exe` for non-standard installs.
DOTNET           ?= dotnet
PWSH             ?= powershell -NoProfile -ExecutionPolicy Bypass -File

.PHONY: help check clean format install install-dev-nina uninstall run-nina kill-nina \
        build-debug build-release build-package build-manifest \
        test-env test-unit test-format test-reachability version-check restore

.DEFAULT_GOAL := check

help:  ## Show available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-22s %s\n", $$1, $$2}'

check: test-env build-release test-unit test-format test-reachability version-check  ## Default: full read-only quality gate

clean:  ## dotnet clean + remove bin/, obj/
	-"$(DOTNET)" clean
	rm -rf bin obj tests/bin tests/obj

format:  ## Apply dotnet format in place
	"$(DOTNET)" format NINA.Plugin.PrometheusExporter.sln

restore:  ## dotnet restore (regenerates packages.lock.json for both projects). RESTORE_FLAGS=--locked-mode in CI.
	"$(DOTNET)" restore $(RESTORE_FLAGS)
	"$(DOTNET)" restore $(TEST_PROJECT) $(RESTORE_FLAGS)

install: build-release  ## Build Release + copy DLLs to NINA Plugins dir
	$(PWSH) scripts/install.ps1

# Renamed from install-dev: standards/build/makefile.md reserves install-dev for editable installs
# with dev extras. Here we want a NINA-specific dev-loop convenience (kill NINA, install plugin,
# relaunch NINA) so the file lock is released before the copy.
install-dev-nina: kill-nina install run-nina  ## NINA dev-loop: kill NINA, install, relaunch

kill-nina:  ## Stop any running NINA process so its DLL is free to overwrite
	$(PWSH) scripts/kill-nina.ps1

uninstall:  ## Remove the plugin install directory
	$(PWSH) scripts/uninstall.ps1

run-nina:  ## Kill any running NINA, relaunch
	$(PWSH) scripts/run-nina.ps1

build-debug: restore  ## dotnet build -c Debug
	"$(DOTNET)" build -c Debug

build-release: restore  ## dotnet build -c Release
	"$(DOTNET)" build -c Release

build-package: build-release  ## Zip Release output for GitHub release
	$(PWSH) scripts/build-package.ps1

test-env:  ## Preflight: .NET 8 SDK, NINA install path, plugins dir writable
	$(PWSH) scripts/test-env.ps1

test-unit: build-release  ## Run xUnit tests
	"$(DOTNET)" test $(TEST_PROJECT) -c Release

test-format:  ## Read-only formatting check
	"$(DOTNET)" format NINA.Plugin.PrometheusExporter.sln --verify-no-changes

test-reachability:  ## Verify all content files are reachable from CLAUDE.md / README.md
	python scripts/reachability.py --check

version-check:  ## Validate AssemblyInfo version format + source-pair match (and bump vs origin/$$BASE_REF when set)
	$(PWSH) scripts/version-check.ps1

build-manifest: build-package  ## Emit manifest.json for the NINA plugin-manifests repo (uses release zip checksum)
	$(PWSH) scripts/build-manifest.ps1
