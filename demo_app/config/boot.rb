ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "logger"  # a workaround for https://github.com/rails/rails/issues/54263 in Rails 7.0
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
