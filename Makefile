# NINA Prometheus Exporter — Makefile
# Verb-[qualifier-]noun grammar per ~/source/standards/build/makefile.md
# Whitelisted bare verbs: help, check, clean, format, install, uninstall, run

PROJECT          ?= NINA.Plugin.PrometheusExporter
TEST_PROJECT     ?= tests/NINA.Plugin.PrometheusExporter.Tests.csproj
DOTNET           ?= C:\Program Files\dotnet\dotnet.exe
PWSH             ?= powershell -NoProfile -ExecutionPolicy Bypass -File

.PHONY: help check clean format install install-dev uninstall run-nina kill-nina \
        build-debug build-release build-package \
        test-env test-unit test-format restore

.DEFAULT_GOAL := check

help:  ## Show available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-22s %s\n", $$1, $$2}'

check: test-env build-release test-unit test-format  ## Default: full read-only quality gate

clean:  ## dotnet clean + remove bin/, obj/
	-"$(DOTNET)" clean
	rm -rf bin obj tests/bin tests/obj

format:  ## Apply dotnet format in place
	"$(DOTNET)" format

restore:  ## dotnet restore (NuGet packages)
	"$(DOTNET)" restore

install: build-release  ## Build Release + copy DLLs to NINA Plugins dir
	$(PWSH) scripts/install.ps1

install-dev: kill-nina install run-nina  ## kill NINA, install, relaunch (avoids file-lock fight)

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
	"$(DOTNET)" format --verify-no-changes
