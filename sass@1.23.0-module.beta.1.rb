require_relative "sass"

class SassAT1230ModuleBeta1 < Sass
  desc "Stylesheet Preprocessor"
  homepage "https://sass-lang.com"

  url "https://github.com/sass/dart-sass/archive/1.23.0-module.beta.1.tar.gz"
  sha256 "d24cde281e73c01a2d6104ce64df3e1ecd8595ef0f0b9f9927baaa69c97b2bfd"

  depends_on "dart-lang/dart/dart" => :build
end
