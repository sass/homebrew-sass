require "yaml"

class Migrator < Formula
  desc "Sass Migration Tool"
  homepage "https://sass-lang.com/documentation/cli/migrator"

  url "https://github.com/sass/migrator/archive/1.0.0-alpha.4.tar.gz"
  sha256 "b2e24de9698423695bc3cbb7b1e5f375bbc95fe19fafc43993667f9a33210588"

  depends_on "dart-lang/dart/dart" => :build

  def install
    dart = Formula["dart-lang/dart/dart"].opt_bin

    pubspec = YAML.safe_load(File.read("pubspec.yaml"))
    version = pubspec["version"]

    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:sass_migrator"

    system dart/"pub", "get"
    if Hardware::CPU.is_64_bit?
      # Build a native-code executable on 64-bit systems only. 32-bit Dart
      # doesn't support this.
      system dart/"dart2aot", "-Dversion=#{version}", "bin/sass_migator.dart",
             "sass_migrator.dart.native"
      lib.install "sass_migrator.dart.native"

      # Copy the version of the Dart VM we used into our lib directory so that if
      # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
      # which was compiled with an older version.
      cp dart/"dartaotruntime", lib

      (bin/"sass-migrator").write <<SH
#!/bin/sh
exec "#{lib}/dartaotruntime" "#{lib}/sass_migrator.dart.native" "$@"
SH
    else
      system dart/"dart",
             "--snapshot=sass_migrator.dart.app.snapshot",
             "--snapshot-kind=app-jit",
             "bin/sass_migrator.dart", "tool/app-snapshot-input.scss"
      lib.install "sass_migrator.dart.app.snapshot"

      # Copy the version of the Dart VM we used into our lib directory so that if
      # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
      # which was compiled with an older version.
      cp dart/"dart", lib

      (bin/"sass-migrator").write <<SH
#!/bin/sh
exec "#{lib}/dart" "-Dversion=#{version}" "#{lib}/sass_migrator.dart.app.snapshot" "$@"
SH
    end
    chmod 0555, "#{bin}/sass-migrator"
  end

  test do
    (testpath/"test.scss").write("a {b: abs(-1)}");
    assert_match "b: math.abs(-1);",
                 shell_output("#{bin}/sass-migrator -nv module test.scss 2>&1")
  end
end
