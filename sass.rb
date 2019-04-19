require "yaml"

class Sass < Formula
  desc "Stylesheet Preprocessor"
  homepage "https://sass-lang.com"

  url "https://github.com/sass/dart-sass/archive/1.19.0.tar.gz"
  sha256 "a6ff17eea4b784ccb4f2ce7e95334b5728cba41de1b0722c7221890f4ce45613"

  depends_on "dart-lang/dart/dart" => :build

  def install
    dart = Formula["dart-lang/dart/dart"].opt_bin

    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:sass"
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
