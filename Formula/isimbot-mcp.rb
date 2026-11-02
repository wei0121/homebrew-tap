# Source is pinned to an immutable commit. Update URL, version and SHA256 together.
# idb resource definitions adapted from facebook/homebrew-fb (Meta Platforms).
# See THIRD_PARTY_LICENSES/homebrew-fb.txt for the upstream BSD license.
class IsimbotMcp < Formula
  include Language::Python::Virtualenv

  desc "iSimBot-MCP: MCP server for iOS simulator automation"
  homepage "https://github.com/wei0121/iSimBot-mcp"
  url "https://github.com/wei0121/iSimBot-mcp/archive/8916abcc78fc0bd80b413c210bd20ac4f9354804.tar.gz"
  version "1.0.0"
  sha256 "a477a632319608e4a7ce8055baa82b5d9ae620bbe1955f9ac4381aece5de2e0d"
  license "MIT"
  revision 1

  depends_on arch: :arm64
  depends_on macos: :sequoia
  depends_on xcode: "26.0"
  depends_on "node"
  depends_on "python@3.14"

  resource "fb-idb" do
    url "https://github.com/facebook/idb/releases/download/v1.7.8/fb_idb-1.7.8-py3-none-any.whl"
    sha256 "ed8557a4c54ffee53006c1fe63f070cda567949312ab24be56faf987c5a3d04b"
  end

  resource "aiofiles" do
    url "https://files.pythonhosted.org/packages/41/c3/534eac40372d8ee36ef40df62ec129bee4fdb5ad9706e58a29be53b2c970/aiofiles-25.1.0.tar.gz"
    sha256 "a8d728f0a29de45dc521f18f07297428d56992a742f0cd2701ba86e44d23d5b2"
  end

  resource "grpclib" do
    url "https://files.pythonhosted.org/packages/5b/28/5a2c299ec82a876a252c5919aa895a6f1d1d35c96417c5ce4a4660dc3a80/grpclib-0.4.9.tar.gz"
    sha256 "cc589c330fa81004c6400a52a566407574498cb5b055fa927013361e21466c46"
  end

  resource "h2" do
    url "https://files.pythonhosted.org/packages/e7/85/7c366e69d84c17bb778fe41419e1fbcce3033d5b7ce29bbffff0a98b859f/h2-4.4.1.tar.gz"
    sha256 "4e866ffb1a869ae14dd9b5e6beb5c24a13da0495ad72b65925ded182521c1516"
  end

  resource "hpack" do
    url "https://files.pythonhosted.org/packages/26/5b/fcabf6028144a8723726318b07a32c2f3314acdff6265743cf08a344b18e/hpack-4.2.0.tar.gz"
    sha256 "0895cfa3b5531fc65fe439c05eb65144f123bf7a394fcaa56aa423548d8e45c0"
  end

  resource "hyperframe" do
    url "https://files.pythonhosted.org/packages/02/e7/94f8232d4a74cc99514c13a9f995811485a6903d48e5d952771ef6322e30/hyperframe-6.1.0.tar.gz"
    sha256 "f630908a00854a7adeabd6382b43923a4c4cd4b821fcb527e6ab9e15382a3b08"
  end

  resource "multidict" do
    url "https://files.pythonhosted.org/packages/81/08/7036c080d7117f28a4af526d794aab6a84463126db031b007717c1a6676e/multidict-6.7.1-py3-none-any.whl"
    sha256 "55d97cc6dae627efa6a6e548885712d4864b81110ac76fa4e534c03819fa4a56"
  end

  resource "protobuf" do
    url "https://files.pythonhosted.org/packages/19/c7/5f7c636ec43e0c545e28d1f1db71990108306f7bdcb89f069ba97e428e7f/protobuf-7.35.1-py3-none-any.whl"
    sha256 "4bc97768d8fe4ad6743c8a19403e314511ed9f6d13205b687e52421c023ac1b9"
  end

  resource "idb-companion" do
    url "https://github.com/facebook/idb/releases/download/v1.7.8/idb-companion.macos-arm64.tar.gz"
    sha256 "44369a2df0b62e3a1764de61bd09280999c7e9b27ea8f20bff1ea3a9db0302a2"
  end


  def install
    venv = virtualenv_create(libexec/"idb-venv", "python3.14")
    venv.pip_install resources.reject { |r| %w[fb-idb idb-companion].include?(r.name) }
    venv.pip_install resource("fb-idb")
    companion = libexec/"idb-companion"
    resource("idb-companion").stage do
      companion.install Dir["*"]
    end
    odie "idb_companion missing from archive" unless (companion/"idb_companion").exist?
    odie "Companion resources missing" unless (companion/"Resources/libShimulator-iOS.dylib").exist?
    system Formula["node"].opt_bin/"npm", "ci", "--include=dev", "--ignore-scripts", "--no-audit", "--no-fund"
    system Formula["node"].opt_bin/"npm", "run", "build"
    system Formula["node"].opt_bin/"npm", "prune", "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund"
    libexec.install "dist", "node_modules", "package.json", "package-lock.json"
    chmod 0755, libexec/"dist/index.js"
    # Desktop clients may have a minimal PATH. Keep stable opt paths across upgrades.
    runtime_path = [Formula["node"].opt_bin, opt_libexec/"idb-venv/bin",
                    opt_libexec/"idb-companion", "/usr/bin", "/bin", "/usr/sbin", "/sbin"].join(":")
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
    assert_match "usage", shell_output("#{libexec}/idb-venv/bin/idb --help")
    assert_match "build_date", shell_output("#{libexec}/idb-companion/idb_companion --version")
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
