require "yaml"

module ::Utils
  def self.add_clang_version_to_conan_settings(version)
    system "conan", "config", "init"
    conan_home = safe_popen_read("conan", "config", "home").strip
    settings_file = "#{conan_home}/settings.yml"
    settings = YAML.load_file(settings_file, aliases: true)
    clang_versions = settings["compiler"]["clang"]["version"]
    unless clang_versions.include?(version)
      clang_versions << version
      File.write(settings_file, YAML.dump(settings))
    end
  end
end

class CatboostCli < Formula
  desc "Fast, scalable, high performance Gradient Boosting on Decision Trees cli tool"
  homepage "https://catboost.ai"
  url "https://github.com/catboost/catboost.git",
    tag:      "v1.2.7",
    revision: "f903943a8cd903a117c3d3c8421cc72d3910562c"
  license "Apache-2.0"
  head "https://github.com/catboost/catboost.git", branch: "master"

  bottle do
    root_url "https://github.com/cdalvaro/homebrew-tap/releases/download/catboost-cli-1.2.5"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "f6663c246664072a707fbfba94c277cdd1cd3e9be215d122ba2da447159ecb6d"
    sha256 cellar: :any_skip_relocation, ventura:      "dbd6b95cf9ae2e558d5de488220af12dd6fa61d49cadc7348f4886a7c07bd99c"
    sha256 cellar: :any_skip_relocation, monterey:     "31fdc2ffa55461131070c5a93096df2ef32e8f029dfcb55ba8d05a9d1abf3cda"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "6d53035f0d4f00efae54d652799fed344f6f645bef975829c3b6209c2760775c"
  end

  depends_on "cmake" => :build
  depends_on "conan@1" => :build
  depends_on "ninja" => :build

  uses_from_macos "llvm" => :build

  on_linux do
    depends_on "lld"
  end

  resource "testdata" do
    url "https://github.com/catboost/tutorials.git",
        branch:   "master",
        revision: "b85bed6b57feafc84e3984872260f9888c9f3bae"
  end

  def install
    Utils.add_clang_version_to_conan_settings(Formula["llvm"].version.major.to_s) if ENV.key?("GITHUB_ACTIONS")

    args = [
      "-DCATBOOST_COMPONENTS=app",
      "-DCMAKE_POSITION_INDEPENDENT_CODE=On",
      "-DHAVE_CUDA=no",
      "-DCMAKE_TOOLCHAIN_FILE=#{buildpath}/build/toolchains/clang.toolchain",
    ]

    cmakepath = buildpath/"cmake-build"
    system "cmake", "-S", ".", "-B", cmakepath, "-G", "Ninja", *args, *std_cmake_args
    system "ninja", "-C", cmakepath, "catboost"
    bin.install cmakepath/"catboost/app/catboost"
  end

  test do
    assert_match %r{Branch: tags/v#{version}}, shell_output("#{bin}/catboost --version")

    resource("testdata").stage do
      cd "cmdline_tutorial" do
        system bin/"catboost", "fit", "--learn-set", "train.tsv", "--test-set", "test.tsv", "--column-description",
"train.cd", "--loss-function", "RMSE", "--iterations", "1000", "--seed", 1, "--verbose", "0"
        system bin/"catboost", "calc", "-m", "model.bin", "--input-path", "test.tsv", "--cd", "train.cd", "-o",
"eval.tsv", "-T", "1", "--output-columns", "DocId,Probability,Target,name,profession,#3"

        assert_equal <<~EOF, File.read("eval.tsv")
          DocId\tProbability\tTarget\tname\tprofession\t#3
          0\t0.5755451606\t0\tAlex\tdoctor\tsenior
          1\t0.5819929128\t1\tDemid\tdentist\tjunior
          2\t0.6399684939\t1\tValentin\tprogrammer\tsenior
          3\t0.6479485073\t1\tIvan\tdoctor\tmiddle
          4\t0.5757021776\t0\tIvan\tdentist\tsenior
          5\t0.5543948515\t0\tValentin\tdentist\tmiddle
          6\t0.6022880215\t0\tMilan\tlawyer\tmiddle
          7\t0.5760162599\t0\tMilan\tprogrammer\tsenior
          8\t0.6423663059\t1\tValentin\tlawyer\tsenior
          9\t0.656955474\t1\tDemid\tdoctor\tmiddle
          10\t0.5992072123\t0\tValentin\tdentist\tmiddle
          11\t0.5782185863\t0\tMilan\tprogrammer\tsenior
          12\t0.6055756528\t1\tValentin\tdentist\tjunior
          13\t0.5209084714\t0\tIvan\tdoctor\tsenior
          14\t0.5840158456\t0\tValentin\tdentist\tsenior
          15\t0.60573894\t0\tMilan\tdentist\tsenior
          16\t0.5926617612\t0\tDemid\tlawyer\tmiddle
          17\t0.6298311784\t0\tValentin\tprogrammer\tsenior
          18\t0.6230447361\t1\tMilan\tlawyer\tsenior
          19\t0.6311443544\t1\tValentin\tlawyer\tjunior
        EOF
      end
    end
  end
end
