# Agent Note: Compare Lefthook lock identities across Windows stat APIs

Status: implemented

English | [中文](2026-09-03-windows-lefthook-lock-identity.zh.md)

## Problem

Node's Windows `fstat` and `lstat` calls report different `dev` values for the same lock file, while the file index remains stable.

The worktree-local Lefthook installer compared both fields after creating and releasing its lock, so every Windows install reported changed ownership and left a lock that blocked the next install as stale.

## Decision

`scripts/install-lefthook.mjs` compares the file index on Windows and compares both the device and file index on other platforms.

The shared identity check protects lock publication, release, and concurrent initialization checks; exact lock contents, regular-file checks, symlink rejection, and owner-PID checks remain unchanged.

The installer test suite includes a Windows-only regression that runs a real fixture installation and verifies both successful completion and lock cleanup.

## Alternatives considered

**Ignore file identity on Windows.** Rejected because a replacement lock at the same path must still be detected before removal.

**Normalize `fstat` through another path lookup.** Rejected because an extra lookup would widen the race between lock creation and identity verification.

**Compare timestamps or file size instead.** Rejected because those fields can remain equal when another process replaces the lock; the Windows file index is the stable identity exposed by both calls.

## Consequences

Windows installs no longer fail on the normal `fstat`/`lstat` metadata difference, and successful installs release their repository lock for later worktrees.

Replacement detection still depends on the file index on Windows and on the device-plus-file-index pair elsewhere; manual recovery remains required for locks whose owner process has exited.

## Verification

The Windows Lefthook fixture suite passes after the identity check, including concurrent installation, release, stale-lock, and ownership-change cases.
