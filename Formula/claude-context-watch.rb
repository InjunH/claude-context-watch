class ClaudeContextWatch < Formula
  desc "Real-time context window monitor for Claude Code"
  homepage "https://github.com/anthropics/claude-context-watch"
  url "https://github.com/anthropics/claude-context-watch/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/anthropics/claude-context-watch.git", branch: "main"

  depends_on "jq"
  depends_on "bash"

  def install
    bin.install "bin/claude-context-watch"
    (share/"claude-context-watch").install Dir["lib/*"]
  end

  def post_install
    ohai "Setting up Claude Context Watch..."

    # Create .claude directory if needed
    claude_dir = "#{ENV["HOME"]}/.claude"
    mkdir_p claude_dir unless Dir.exist?(claude_dir)

    # Copy context-writer.sh
    writer_source = "#{share}/claude-context-watch/context-writer.sh"
    writer_dest = "#{claude_dir}/context-writer.sh"

    if File.exist?(writer_source)
      cp writer_source, writer_dest
      chmod 0755, writer_dest
    end

    ohai "Run 'claude-context-watch --setup' to complete configuration"
  end

  def caveats
    <<~EOS
      To complete setup, run:
        claude-context-watch --setup

      This will configure Claude Code's StatusLine feature.
      Then restart Claude Code to activate monitoring.

      Usage:
        claude-context-watch          # Start monitoring
        claude-context-watch -s       # Select session
        claude-context-watch --setup  # Reconfigure StatusLine
    EOS
  end

  test do
    assert_match "claude-context-watch v", shell_output("#{bin}/claude-context-watch --version")
  end
end
