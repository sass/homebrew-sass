# typed: false
# frozen_string_literal: true

require "yaml"

# A formula for the Dart Sass Embedded CLI.
class DartSassEmbedded < Formula
  desc "Stylesheet Preprocessor"
  homepage "https://sass-lang.com"

  url "https://github.com/sass/dart-sass-embedded/archive/1.58.1.tar.gz"
  sha256 "cc05f883c50de01e4fd3bbaf360481a9df18ac401863f0d40b822261e1ea2cd4"

  depends_on "dart-lang/dart/dart" => :build
  depends_on "protobuf" => :build

  def install
    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:sass"

    system _dart/"dart", "pub", "get"
    system _dart/"dart", "run", "grinder", "protobuf"
    # Build a native-code executable on 64-bit systems only. 32-bit Dart
    # doesn't support this.
    if Hardware::CPU.is_64_bit?
      _install_native_executable
    else
      _install_script_snapshot
    end
    chmod 0555, "#{bin}/dart-sass-embedded"
  end

  test do
    assert_match '"id": 0', shell_output("#{bin}/dart-sass-embedded --version")
  end

  private

  def _dart
    @_dart ||= Formula["dart-lang/dart/dart"].libexec/"bin"
  end

  def _version
    @_version ||= YAML.safe_load(File.read("pubspec.yaml"))["version"]
  end

  def _protocol_version
    @_protocol_version ||= File.read("build/embedded-protocol/VERSION").strip
  end

  def _implementation_version
    @_implementation_version ||= YAML.safe_load(File.read("pubspec.lock"))["packages"]["sass"]["version"]
  end

  def _install_native_executable
    system _dart/"dart", "compile", "exe",
           "-Dprotocol-version=#{_protocol_version}",
           "-Dcompiler-version=#{_version}",
           "-Dimplementation-version=#{_implementation_version}",
           "bin/dart_sass_embedded.dart", "-o", "dart-sass-embedded"
    bin.install "dart-sass-embedded"
  end

  def _install_script_snapshot
    system _dart/"dart", "run", "grinder", "pkg-compile-snapshot"
    libexec.install "build/dart-sass-embedded.snapshot"

    # Copy the version of the Dart VM we used into our lib directory so that if
    # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
    # which was compiled with an older version.
    cp _dart/"dart", libexec

    (bin/"dart-sass-embedded").write <<~SH
      #!/bin/sh
      exec "#{libexec}/dart" "#{libexec}/dart-sass-embedded.snapshot" "$@"
    SH
  end
end
