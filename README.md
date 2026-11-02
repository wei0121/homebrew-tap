# Homebrew Tap

Homebrew formulae for [iSimBot-MCP](https://github.com/wei0121/iSimBot-mcp).

## Install

Requires Apple Silicon, macOS 15+, and Xcode 26+ with an iOS simulator runtime.

```bash
brew install wei0121/tap/isimbot-mcp
isimbot setup
```

Choose Claude Code or Codex, then restart the client.

## Update or uninstall

```bash
brew update
brew upgrade wei0121/tap/isimbot-mcp
# To remove:
brew uninstall isimbot-mcp
```

See [installation help](https://github.com/wei0121/iSimBot-mcp/blob/main/doc/installation.md).

## Maintain

The formula pins a source commit and builds it during installation. For each release,
update the source URL, version, and SHA256 together, then test with Homebrew.
