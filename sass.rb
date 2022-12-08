# typed: false
# frozen_string_literal: true

require "yaml"

# A formula for the Sass CLI.
class Sass < Formula
  desc "Stylesheet Preprocessor"
  homepage "https://sass-lang.com"

  url "https://github.com/sass/dart-sass/archive/1.56.2.tar.gz"
  sha256 "10c4f4827e963a2ed5717464a89c8daac7c670d2c5304d0982b930e5e3a7965b"

  depends_on "dart-lang/dart/dart" => :build

  def install
    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:sass"

    system _dart/"dart", "pub", "get"
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

  def _install_native_executable
    system _dart/"dart", "compile", "exe", "-Dversion=#{_version}",
           "bin/sass.dart", "-o", "sass"
    bin.install "sass"
  end

  def _install_script_snapshot
    system _dart/"dart", "compile", "jit-snapshot",
           "-Dversion=#{_version}",
           "-o", "sass.dart.app.snapshot",
           "bin/sass.dart", "--version"
    libexec.install "sass.dart.app.snapshot"

    # Copy the version of the Dart VM we used into our lib directory so that if
    # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
    # which was compiled with an older version.
    cp _dart/"dart", libexec

    (bin/"sass").write <<~SH
      #!/bin/sh
      exec "#{libexec}/dart" "#{libexec}/sass.dart.app.snapshot" "$@"
    SH
  end
end
