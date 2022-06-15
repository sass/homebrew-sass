# typed: false
# frozen_string_literal: true

require "yaml"

# A formula for the Sass migrator CLI.
class Migrator < Formula
  desc "Sass Migration Tool"
  homepage "https://sass-lang.com/documentation/cli/migrator"

  url "https://github.com/sass/migrator/archive/1.5.5.tar.gz"
  sha256 "d1f8abe8fbd28ee0faa2fb0b0fad575fc44d3d8eb7583e8bd45bc94741ad7b02"

  depends_on "dart-lang/dart/dart" => :build

  def install
    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:sass_migrator"

    system _dart/"dart", "pub", "get"
    # Build a native-code executable on 64-bit systems only. 32-bit Dart
    # doesn't support this.
    if Hardware::CPU.is_64_bit?
      _install_native_executable
    else
      _install_script_snapshot
    end
    chmod 0555, "#{bin}/sass-migrator"
  end

  test do
    (testpath/"test.scss").write("a {b: abs(-1)}")
    assert_match "b: math.abs(-1)",
                 shell_output("#{bin}/sass-migrator -nv module test.scss 2>&1")
  end

  private

  def _dart
    @_dart ||= Formula["dart-lang/dart/dart"].libexec/"bin"
  end

  def _version
    @_version ||= YAML.safe_load(File.read("pubspec.yaml"))["version"]
  end

  def _install_native_executable
    system _dart/"dart", "compile", "exe", "-Dversion=#{_version}",
           "bin/sass_migrator.dart", "-o", "sass-migrator"
    bin.install "sass-migrator"
  end

  def _install_script_snapshot
    system _dart/"dart", "compile", "jit-snapshot",
           "-Dversion=#{_version}",
           "-o", "sass_migrator.dart.app.snapshot",
           "bin/sass_migrator.dart", "tool/app-snapshot-input.scss"
    lib.install "sass_mirator.dart.app.snapshot"

    # Copy the version of the Dart VM we used into our lib directory so that if
    # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
    # which was compiled with an older version.
    cp _dart/"dart", lib

    (bin/"sass-migrator").write <<~SH
      #!/bin/sh
      exec "#{lib}/dart" "#{lib}/sass_migrator.dart.app.snapshot" "$@"
    SH
  end
end
