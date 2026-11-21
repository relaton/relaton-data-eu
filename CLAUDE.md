# relaton-data-eu

Data repo for `Relaton::Eu` (EU regulations, directives, decisions). See README.adoc.

- `Gemfile` takes relaton from the git branch `main` (relaton#589 merged
  there; the flavor is not released). Never point it at a feature branch:
  GitHub deletes it at the merge and `bundle install` fails. Change it to the
  released version at the release. `Gemfile.lock` is not in git, so CI
  resolves the Gemfile again on each run; `spec/gemfile_spec.rb` pins the
  source. pubid must be >= 2.0.46 (`Pubid::Eu` with ELI subtypes).
- Check index and Deploy build relaton from `relaton/relaton@main`. They also
  need a relaton/support `data-index/configs.yml` row and a `cimas.yml` entry
  (both handed off).
- `crawler.rb [full|updates]`: no argument means full when
  `cellar-since.txt` is missing or on UTC day 1, else updates. So the
  standard daily cron gives a monthly full crawl and daily updates.
  - full: deletes `index-v*.{yaml,zip}` (never `data/`), then
    `Relaton::Eu::DataFetcher.fetch "eu-cellar", prune: true` (247 pages,
    ~213,400 works, 1.5 h to 4+ h: titles in up to 24 languages).
  - updates: keeps the index, `fetch "eu-cellar-updates"` with no prune (the
    fetcher raises with prune). Fails without `cellar-since.txt`.
  - Both write `cellar-since.txt`; crawler.rb `git add`s it, because the
    shared crawler.yml commits only data/, index files and provenance.
  It writes `index-v2.yaml` only; the shared crawler.yml zips and commits.
  There is no index-v1.
- `check_data.rb [GLOB]` round-trips YAML through `Relaton::Bib::Item`: EU
  items are plain `Bib::ItemData`, there is no `Relaton::Eu::Item`. Read files
  with `encoding: "UTF-8"`, or the string compare fails on non-ASCII.
- A data file carries no `fetched`; `Bibliography#fetch_doc` sets it on read.
- `.github/workflows/*.yml` are byte copies of relaton/support Cimas templates;
  `spec/workflows_spec.rb` pins that (skips when `../support` is absent).
  `crawler.yml` is `gh-actions/data-eu/crawler.yml` (support#101): the shared
  template plus a boolean `full` dispatch input that passes `full` as args.
  support's cimas.yml maps only check_data, crawler and keep-alive for now;
  deploy.yml and check-index.yml wait for the support mapping.
- `spec/fixtures/data/eu-regulation-1227-2011.yaml` is a copy of the relaton
  fixture `spec/eu/fixtures/data/` (DataFetcher output, relaton 3df82dcdd,
  titles in 24 languages). Do not edit it by hand.
- Test: `bundle exec rake` (rspec). The specs never contact CELLAR.
