class Catboost < Formula
  desc "Fast, scalable, high performance Gradient Boosting on Decision Trees cli tool"
  homepage "https://catboost.ai"
  url "https://github.com/catboost/catboost/archive/v0.26.1.tar.gz"
  sha256 "a82971e13facc8421c14755bfc489be9a3d21f81ec529044db90a9b53cc32b01"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/cdalvaro/homebrew-tap/releases/download/catboost-0.26.1"
    sha256 cellar: :any_skip_relocation, big_sur:  "0cf4d7b860a8f51ae08087eb38ca5f566bd030fce862e1d706211f78a915daec"
    sha256 cellar: :any_skip_relocation, catalina: "72ffb0f09f763ce4d06b4620c6c640e0fbbb1bf8c4e1373a4a000dec4b9fce49"
  end

  def install
    cd "#{buildpath}/catboost/app" do
      ENV["YA_CACHE_DIR"] = "./.ya"
      system "../../ya", "make", "-r", "-o", "#{buildpath}/brew-build"
      bin.install "#{buildpath}/brew-build/catboost/app/catboost"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/catboost --version")
  end
end
