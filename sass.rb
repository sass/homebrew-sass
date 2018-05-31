require "yaml"

class Sass < Formula
  desc "Stylesheet Preprocessor"
  homepage "https://sass-lang.com"

  url "https://github.com/sass/dart-sass/archive/1.5.0.tar.gz"
  sha256 "2239539edeaa0e46221e2962fd8f8b35121af58ed1a1a9d93c639428abb94bcf"

  depends_on "dart@2" => :build

  def install
    dart_bin = Formula["dart@2"].opt_bin

    system dart_bin/"pub", "get"
    system dart_bin/"dart",
           "--snapshot=sass.dart.app.snapshot",
           "--snapshot-kind=app-jit",
           "bin/sass.dart", "tool/app-snapshot-input.scss"
    lib.install "sass.dart.app.snapshot"

    # Copy the version of the Dart VM we used into our lib directory so that if
    # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
    # which was compiled with an older version.
    cp dart_bin/"dart", lib

    pubspec = YAML.safe_load(File.read("pubspec.yaml"))
    version = pubspec["version"]

    (buildpath/"sass").write <<EOS
#!/bin/sh
exec "#{lib}/dart" "-Dversion=#{version}" "#{lib}/sass.dart.app.snapshot" "$@"
EOS
    chmod 0555, "sass"
    bin.install("sass")
  end

  test do
    (testpath/"test.scss").write(".class {property: 1 + 1}");
    assert_match "property: 2;", shell_output("#{bin}/sass test.scss 2>&1")
  end
end
