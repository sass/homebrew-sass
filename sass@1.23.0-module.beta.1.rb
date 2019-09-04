require_relative "sass"

class SassAT1230ModuleBeta1 < Sass
  desc "Stylesheet Preprocessor"
  homepage "https://sass-lang.com"

  url "https://github.com/sass/dart-sass/archive/1.23.0-module.beta.1.tar.gz"
  sha256 "73d455eab1bee5ee031fcedf66f43f1e71c1561a54d159d517e49285560bfa56"

  depends_on "dart-lang/dart/dart" => :build
end
