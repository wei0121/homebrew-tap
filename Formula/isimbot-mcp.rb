# Source is pinned to an immutable commit. Update URL, version and SHA256 together.
class IsimbotMcp < Formula
  desc "iSimBot-MCP: MCP server for iOS simulator automation"
  homepage "https://github.com/wei0121/iSimBot-mcp"
  url "https://github.com/wei0121/iSimBot-mcp/archive/8916abcc78fc0bd80b413c210bd20ac4f9354804.tar.gz"
  version "1.0.0"
  sha256 "a477a632319608e4a7ce8055baa82b5d9ae620bbe1955f9ac4381aece5de2e0d"
  license "MIT"

  depends_on arch: :arm64
  depends_on macos: :sequoia
  depends_on xcode: "26.0"
  depends_on "node"
  depends_on "facebook/fb/idb"

  def install
    system Formula["node"].opt_bin/"npm", "ci", "--include=dev", "--ignore-scripts", "--no-audit", "--no-fund"
    system Formula["node"].opt_bin/"npm", "run", "build"
    system Formula["node"].opt_bin/"npm", "prune", "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund"
    libexec.install "dist", "node_modules", "package.json", "package-lock.json"
    chmod 0755, libexec/"dist/index.js"
    # Desktop clients may have a minimal PATH. Keep stable opt paths across upgrades.
    runtime_path = [Formula["node"].opt_bin, Formula["facebook/fb/idb-cli"].opt_bin,
                    Formula["facebook/fb/idb-companion"].opt_bin, "/usr/bin", "/bin", "/usr/sbin", "/sbin"].join(":")
    (bin/"isimbot").write_env_script opt_libexec/"dist/index.js",
      PATH: runtime_path, ISIMBOT_LAUNCHER: (opt_bin/"isimbot").to_s
  end

  def caveats
    <<~EOS
      iSimBot-MCP is installed. CLI: isimbot.

      Get started:
        isimbot doctor
        isimbot setup

      Setup lets you choose Claude Code or Codex.
      Restart the selected client after configuration.

      Help:
        isimbot --help
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/isimbot --version")
    assert_match "isimbot setup", shell_output("#{bin}/isimbot --help")
    # Exercise the native image dependency without opening or changing a simulator.
    system Formula["node"].opt_bin/"node", "--input-type=module", "-e", <<~JS
      import { createRequire } from 'node:module';
      const sharp = createRequire('#{libexec}/package.json')('sharp');
      const image = await sharp({create: {width: 10, height: 20, channels: 3, background: 'white'}}).png().toBuffer();
      const metadata = await sharp(image).metadata();
      if (metadata.width !== 10 || metadata.height !== 20) process.exit(1);
    JS
  end
end
