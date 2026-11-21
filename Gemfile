# frozen_string_literal: true

source "https://rubygems.org"

# The EU flavor lives in the combined `relaton` gem. `Relaton::Eu` is on
# relaton `main` (relaton/relaton#589), not released yet. Take it from `main`,
# never from a feature branch: GitHub deletes the branch at the merge, and
# `bundle install` then fails. When relaton releases the flavor, change this
# line to the released version, for example `gem "relaton", "~> 3.2"`.
gem "relaton", github: "relaton/relaton", branch: "main"

# Pin pubid here too. 2.0.44 is the first release with `Pubid::Eu`
# (pubid#752), which keys index-v2; 2.0.46 reads the ELI subtypes
# (reg_impl, dec_del, ...).
# Verify with `bundle list | grep pubid`.
gem "pubid", "~> 2.0", ">= 2.0.46"

# Pin psych: 5.3.0 breaks the YAML round-trip that check_data.rb depends on
# (key ordering / quoting). Same pin as relaton-data-sae, -adobe and -oiml.
gem "psych", "~> 5.2.6"

# check_data.rb prints a line diff on a round-trip mismatch. Declared here,
# not left to a transitive dependency of relaton.
gem "diff-lcs", "~> 1.5"

gem "rake", "~> 13.0"

group :test do
  gem "rspec", "~> 3.13"
end
