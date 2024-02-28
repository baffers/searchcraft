# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in searchcraft.gemspec
gemspec

group :development, :test do
  gem "standard", "~> 1.3", require: false
  gem "erb_lint", require: false
  gem "ripper-tags", "~> 1.0", require: false
end

gem "steep", "~> 1.5"

# Need scenic HEAD to get populated? method
# https://github.com/scenic-views/scenic/commit/104d888d26e52999fa0e6b90c06a5953de072e35
# Waiting on a release after v1.7.0
gem "scenic", github: "scenic-views/scenic"
