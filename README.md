# Homebrew Tap

Homebrew formulae for [iSimBot-MCP](https://github.com/wei0121/iSimBot-mcp).

## Install

Requires Apple Silicon, macOS 15+, and Xcode 26+ with an iOS simulator runtime.

```bash
brew install wei0121/tap/isimbot-mcp
isimbot setup
```

Choose Claude Code or Codex, then restart the client.
Node and Python are bundled privately; global runtimes are not upgraded.

## Update or uninstall

```bash
brew update
brew upgrade wei0121/tap/isimbot-mcp
# To remove:
brew uninstall isimbot-mcp
```

See [installation help](https://github.com/wei0121/iSimBot-mcp/blob/main/doc/installation.md).

## Maintain

The **Update iSimBot formula** Action checks the latest stable iSimBot-MCP
Release every hour. You can also run it manually from **Actions → Update iSimBot
formula → Run workflow**.

When a newer version is available, it verifies the published formula, archive URL
and SHA256, then commits and pushes the formula to `main`. It uses the built-in
`GITHUB_TOKEN`; no extra secret is needed. Branch rules must allow direct updates.
No commit is created when the version is unchanged; older releases never downgrade
the formula. Scheduled runs can be delayed by GitHub.

Private Node/Python versions and checksums come from the published formula.
Maintain their security updates in the source project.
