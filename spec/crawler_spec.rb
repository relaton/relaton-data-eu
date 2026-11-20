# frozen_string_literal: true

require "relaton/eu/data_fetcher"

RSpec.describe "crawler.rb" do
  # DataFetcher::SINCE_FILE; the literal keeps the spec independent of the
  # relaton revision that the Gemfile resolves.
  let(:since_file) { "cellar-since.txt" }
  let(:today) { Time.utc(2026, 11, 20, 14) }

  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  before do
    FileUtils.mkdir_p "data"
    File.write "data/eu-stale.yaml", "stale"
    %w[index-v2.yaml index-v2.zip index-v1.yaml].each { |f| File.write f, "old" }
    # A source file next to the indexes: a bare `index*` glob deletes it
    # (the relaton-data-bipm bug).
    File.write "index_builder.rb", "# source"
    allow(Relaton::Eu::DataFetcher).to receive(:fetch)
    allow(Time).to receive(:now).and_return(today)
  end

  def run_crawler(*args)
    stub_const("ARGV", args)
    load File.join(ROOT, "crawler.rb")
  end

  def expect_full
    expect(Relaton::Eu::DataFetcher).to have_received(:fetch)
      .with("eu-cellar", prune: true)
  end

  def expect_updates
    expect(Relaton::Eu::DataFetcher).to have_received(:fetch)
      .with("eu-cellar-updates")
  end

  context "without cellar-since.txt" do
    it "runs the full crawl in prune mode" do
      run_crawler
      expect_full
    end

    # prune mode deletes stale files only after a near-complete crawl (core's
    # 90% guard). An `rm -rf data` first would publish a truncated crawl as a
    # mass deletion.
    it "keeps data/ and removes only the indexes before the fetch" do
      expect(Relaton::Eu::DataFetcher).to receive(:fetch) do
        expect(File).to exist("data/eu-stale.yaml")
        expect(Dir.glob("index-v*")).to be_empty
      end
      run_crawler
    end

    it "keeps non-index files that start with 'index'" do
      run_crawler
      expect(File).to exist("index_builder.rb")
    end
  end

  context "with cellar-since.txt" do
    before { File.write since_file, "2026-11-19T14:00:00Z\n" }

    it "runs an update, without prune" do
      run_crawler
      expect_updates
    end

    # An update adds to the existing index; a deleted index would leave only
    # the changed acts in it.
    it "keeps the index for an update" do
      expect(Relaton::Eu::DataFetcher).to receive(:fetch) do
        expect(File).to exist("index-v2.yaml")
      end
      run_crawler
    end

    it "runs the full crawl on the first day of the month (UTC)" do
      allow(Time).to receive(:now).and_return(Time.utc(2026, 12, 1, 14))
      run_crawler
      expect_full
    end

    it "runs the full crawl when the argument is 'full'" do
      run_crawler "full"
      expect_full
    end
  end

  it "runs an update when the argument is 'updates', on any day" do
    allow(Time).to receive(:now).and_return(Time.utc(2026, 12, 1, 14))
    File.write since_file, "2026-11-30T14:00:00Z\n"
    run_crawler "updates"
    expect_updates
  end

  it "stops on an unknown argument, before any fetch" do
    expect { run_crawler "all" }.to raise_error(SystemExit)
    expect(Relaton::Eu::DataFetcher).not_to have_received(:fetch)
    expect(File).to exist("index-v2.yaml")
  end

  # The shared crawler.yml commits only data/, index files and its own
  # provenance; any other file is the fetch command's to stage.
  it "stages cellar-since.txt in a git work tree" do
    system "git", "init", "-q", "."
    allow(Relaton::Eu::DataFetcher).to receive(:fetch) do
      File.write since_file, "2026-11-20T14:00:00Z\n"
    end
    run_crawler
    staged = `git diff --cached --name-only`.split("\n")
    expect(staged).to include since_file
  end

  it "does not fail outside a git work tree" do
    allow(Relaton::Eu::DataFetcher).to receive(:fetch) do
      File.write since_file, "2026-11-20T14:00:00Z\n"
    end
    expect { run_crawler }.not_to raise_error
  end
end
