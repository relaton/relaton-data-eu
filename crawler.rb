# frozen_string_literal: true

# Crawler entry point. relaton/support's shared crawler.yml runs
# `bundle exec ruby crawler.rb [ARGS]`, then zips every changed index*.yaml and
# commits data/ with the yaml and zip. Nothing is zipped here.
#
# Reads the EU Publications Office CELLAR SPARQL endpoint (no key): CELEX
# sector 3, types R / L / D (regulations, directives, decisions).
#
#   bundle exec ruby crawler.rb           # update, or full (see below)
#   bundle exec ruby crawler.rb full      # full crawl, with prune
#   bundle exec ruby crawler.rb updates   # only the works changed since
#
# With no argument the run is a full crawl when cellar-since.txt is missing
# (a new repo) or on the first day of the month (UTC), and an update run on
# every other day. So the daily cron of the shared crawler.yml gives a monthly
# full crawl with daily updates between, and needs no per-repo template.
#
# - Full crawl (`eu-cellar`): every year from 1952, 247 pages for about
#   213,400 works, about 1.5 hours to more than 4 hours (each document has
#   a title in every language of the act, up to 24).
# - Update run (`eu-cellar-updates`): the works CELLAR changed since one day
#   before the last finished run, 1 to about 12 pages. It cannot see a work
#   CELLAR deleted, which is why the full crawl still runs monthly.
#
# Both write cellar-since.txt, the start time of the run. The next update run
# reads from it, so the repo must commit it.

require "fileutils"
require "relaton/eu/data_fetcher"

since_file = "cellar-since.txt"

mode = case ARGV.first
       when "full" then :full
       when "updates" then :updates
       when nil, ""
         if !File.exist?(since_file) || Time.now.utc.day == 1
           :full
         else
           :updates
         end
       else
         abort "Unknown argument `#{ARGV.first}`, expected `full` or `updates`"
       end

if mode == :full
  # Narrower than `index*`, which would also match a Ruby source named
  # index*.rb next to this file -- relaton-data-bipm hit that bug.
  # spec/crawler_spec.rb guards it. An update run keeps the index: it adds
  # the changed acts to it.
  FileUtils.rm Dir.glob("index-v*.{yaml,zip}")

  # data/ is kept, not removed: `prune: true` deletes the files this run did
  # not write (repealed or re-keyed acts), but only when the run wrote at
  # least 90% of the existing corpus. A page that keeps failing raises before
  # the index is written, so a failed crawl leaves data/ as it was, where an
  # `rm -rf data` would commit and publish a mass deletion.
  Relaton::Eu::DataFetcher.fetch "eu-cellar", prune: true
else
  # No prune: an update writes only the changed acts, and the fetcher raises
  # ArgumentError with `prune: true`.
  Relaton::Eu::DataFetcher.fetch "eu-cellar-updates"
end

# The shared crawler.yml commits only data/, the index files and its own
# provenance.json; another file is the fetch command's to stage. Outside a
# git work tree (a local run in a copy) this does nothing.
if File.exist?(since_file)
  system "git", "add", "--", since_file, out: File::NULL, err: File::NULL
end
