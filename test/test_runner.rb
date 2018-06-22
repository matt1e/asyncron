# frozen_string_literal: true

require "asyncron"
require "minitest/autorun"

Dir["test/**/*_spec.rb"].each { |f| load f }
