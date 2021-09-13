require "yaml"

class Sass < Formula
  desc "Stylesheet Preprocessor"
  homepage "https://sass-lang.com"

  url "https://github.com/sass/dart-sass/archive/1.39.2.tar.gz"
  sha256 "788d604273e97a5fb32c92684c32d6856d1701393d0e82b2a11ba35f3836f9fc"

  depends_on "dart-lang/dart/dart" => :build

  def install
    dart = Formula["dart-lang/dart/dart"].libexec/"bin"

    pubspec = YAML.safe_load(File.read("pubspec.yaml"))
    version = pubspec["version"]

    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:sass"

    system dart/"dart", "pub", "get"
    if Hardware::CPU.is_64_bit?
      # Build a native-code executable on 64-bit systems only. 32-bit Dart
      # doesn't support this.
      system dart/"dart", "compile", "exe", "-Dversion=#{version}",
             "bin/sass.dart", "-o", "sass"
      bin.install "sass"
    else
      system dart/"dart", "compile", "jit-snapshot",
             "-Dversion=#{version}",
             "-o", "sass.dart.app.snapshot",
             "bin/sass.dart", "tool/app-snapshot-input.scss"
      lib.install "sass.dart.app.snapshot"

      # Copy the version of the Dart VM we used into our lib directory so that if
      # the user upgrades their Dart VM version it doesn't break Sass's snapshot,
      # which was compiled with an older version.
      cp dart/"dart", lib

      (bin/"sass").write <<~SH
        #!/bin/sh
        exec "#{lib}/dart" "#{lib}/sass.dart.app.snapshot" "$@"
      SH
    end
    chmod 0555, "#{bin}/sass"
  end

  test do
    (testpath/"test.scss").write(".class {property: 1 + 1}")
    assert_match "property: 2;", shell_output("#{bin}/sass test.scss 2>&1")
  end
end
