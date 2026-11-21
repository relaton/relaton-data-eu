# frozen_string_literal: true

require "bundler"

# Gemfile.lock is not in git: every crawler run resolves the Gemfile again.
# A feature branch of relaton disappears when its PR merges (GitHub deletes
# it), and then `bundle install` fails before the crawler starts.
RSpec.describe "Gemfile" do
  let(:relaton) do
    dsl = Bundler::Dsl.new
    dsl.eval_gemfile File.join(ROOT, "Gemfile")
    dsl.dependencies.find { |d| d.name == "relaton" }
  end

  it "takes relaton from a release or from the relaton main branch" do
    source = relaton.source
    next if source.nil? # a rubygems release

    # Not `path:` either: a local checkout does not exist on CI.
    expect(source).to be_a(Bundler::Source::Git)
    expect(source.uri).to match(%r{github\.com/relaton/relaton(\.git)?\z})
    expect(source.branch).to eq "main"
  end
end
