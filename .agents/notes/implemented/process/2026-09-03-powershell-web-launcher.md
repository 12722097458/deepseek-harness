# Agent Note: Provide guided cross-platform Web launchers

Status: implemented

English | [中文](2026-09-03-powershell-web-launcher.zh.md)

## Problem

`pnpm dsh web` requires generated package and frontend artifacts, but a source checkout does not explain which build steps to run or which tokenized URL to open.

Windows and macOS/Linux users also need clear recovery messages when they skip a build or choose an invalid port.

## Decision

`deploy/start-web.ps1` runs from the repository root, checks `pnpm`, builds the complete artifact tree by default, and starts `pnpm dsh web --no-open` on `127.0.0.1`.

`deploy/start-web.bat` delegates to PowerShell for double-click and Command Prompt use. `deploy/start-web.sh` provides the same workflow for macOS/Linux, including equivalent long options and browser opening through `open` or `xdg-open`.

The launchers validate required sentinel artifacts for skip-build mode, support port and browser options, and print the exact tokenized URL with an explicit browser-opening instruction.

README language pairs document the platform launchers and their options; tests verify all launcher files are present and the Windows launcher rejects invalid ports before a build or server launch.

## Alternatives considered

**Keep the manual build and launch commands only.** Rejected because missing artifacts produce a late runtime error with no guided recovery path.

**Let `dsh web` open the browser directly.** Rejected because the launcher must show the tokenized address consistently and support terminals where browser handoff is unavailable.

**Start a background server and return immediately.** Rejected because users need the server logs and `Ctrl+C` lifecycle in the same terminal.

## Consequences

Contributors on Windows, macOS, and Linux have documented commands that prepare artifacts, start the server, and identify the exact address to open in a browser.

`-SkipBuild` trusts the three sentinel files and does not prove every bundle is current; users should omit it after source or dependency changes.
