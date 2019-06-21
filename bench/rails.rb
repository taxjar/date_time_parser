# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'activesupport', '= 4.2.9'
  gem 'benchmark-ips'
end

require 'time'
require 'benchmark/ips'
require 'active_support'
require 'active_support/core_ext/date_time'

puts "\nBenchmarking Ruby Time.parse with ActiveSupport"
samples = File.read('test/fixture/date_formats_samples.txt').split("\n").freeze
could_not_parse = 0

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report('Time.parse') do
    could_not_parse = 0
    samples.map do |v|
      begin
        Time.parse(v)
      rescue ArgumentError
        nil
      end
    end
  end

  x.report('Date.parse') do
    could_not_parse = 0
    samples.map do |v|
      begin
        Date.parse(v)
      rescue ArgumentError
        could_not_parse += 1
      end
    end
  end

  x.report('DateTime.parse') do
    could_not_parse = 0
    samples.map do |v|
      begin
        DateTime.parse(v)
      rescue ArgumentError
        could_not_parse += 1
      end
    end
  end

  x.compare!
end

puts "Failed to parse #{could_not_parse}"
