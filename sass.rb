require "yaml"

class Sass < Formula
  desc "Stylesheet Preprocessor"
  homepage "https://sass-lang.com"

  url "https://github.com/sass/dart-sass/archive/1.9.0.tar.gz"
  sha256 "9aa644cfce9b28abaac641220870418cdb14bbe673c809e8f1b07e6023e1483d"

  depends_on "dart-lang/dart/dart@2" => :build

  def install
    dart = Formula["dart-lang/dart/dart@2"].opt_bin

    system dart/"pub", "get"
    system dart/"dart",
           "--snapshot=sass.dart.app.snapshot",
           "--snapshot-kind=app-jit",
           "bin/sass.dart", "tool/app-snapshot-input.scss"
    lib.install "sass.dart.app.snapshot"

    # Copy the version of the Dart VM we used into our lib directory so that if
    # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
    # which was compiled with an older version.
    cp dart/"dart", lib

    pubspec = YAML.safe_load(File.read("pubspec.yaml"))
    version = pubspec["version"]

    (bin/"sass").write <<SH
#!/bin/sh
exec "#{lib}/dart" "-Dversion=#{version}" "#{lib}/sass.dart.app.snapshot" "$@"
SH
    chmod 0555, "#{bin}/sass"
  end

  test do
    (testpath/"test.scss").write(".class {property: 1 + 1}");
    assert_match "property: 2;", shell_output("#{bin}/sass test.scss 2>&1")
  end
end
