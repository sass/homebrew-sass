# typed: false
# frozen_string_literal: true

require "yaml"

# A formula for the Sass CLI.
class Sass < Formula
  desc "Stylesheet Preprocessor"
  homepage "https://sass-lang.com"
  url "https://github.com/sass/dart-sass/archive/1.89.2.tar.gz"
  sha256 "4a2f78270eef196ecb24d37b0563a7da642463c678666e58f6f2028cb06aeb29"
  license "MIT"
  head "https://github.com/sass/dart-sass.git", branch: "main"

  depends_on "buf" => :build
  depends_on "dart-lang/dart/dart" => :build

  resource "language" do
    url "https://github.com/sass/sass.git",
      revision: "dae75bd941e507f0e88f53b2616fbebe0b4a6572"
  end

  def install
    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:sass"

    (buildpath/'build/language').install resource("language")

    system _dart/"dart", "pub", "get"
    ENV["UPDATE_SASS_PROTOCOL"] = "false"
    system _dart/"dart", "run", "grinder", "protobuf"
    ENV.delete "UPDATE_SASS_PROTOCOL"

    # Build a native-code executable on 64-bit systems only. 32-bit Dart
    # doesn't support this.
    if Hardware::CPU.is_64_bit?
      _install_native_executable
    else
      _install_script_snapshot
    end
    chmod 0555, "#{bin}/sass"
  end

  test do
    (testpath/"test.scss").write(".class {property: 1 + 1}")
    assert_match "property: 2;", shell_output("#{bin}/sass test.scss 2>&1")
  end

  private

  def _dart
    @_dart ||= Formula["dart-lang/dart/dart"].libexec/"bin"
  end

  def _version
    @_version ||= YAML.safe_load(File.read("pubspec.yaml"))["version"]
  end

  def _protocol_version
    @_protocol_version ||= File.read("build/language/spec/EMBEDDED_PROTOCOL_VERSION").strip
  end

  def _install_native_executable
    system _dart/"dart", "compile", "exe",
           "-Dversion=#{_version}",
           "-Dcompiler-version=#{_version}",
           "-Dprotocol-version=#{_protocol_version}",
           "bin/sass.dart", "-o", "sass"
    bin.install "sass"
  end

  def _install_script_snapshot
    system _dart/"dart", "compile", "jit-snapshot",
           "-Dversion=#{_version}",
           "-Dcompiler-version=#{_version}",
           "-Dprotocol-version=#{_protocol_version}",
           "-o", "sass.snapshot",
           "bin/sass.dart", "--version"
    libexec.install "sass.snapshot"

    # Copy the version of the Dart VM we used into our lib directory so that if
    # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
    # which was compiled with an older version.
    cp _dart/"dart", libexec

    (bin/"sass").write <<~SH
      #!/bin/sh
      exec "#{libexec}/dart" "#{libexec}/sass.snapshot" "$@"
    SH
  end
end
