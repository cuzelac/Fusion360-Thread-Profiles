#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rake/testtask'

# Set the default task to run tests
task default: :test

# Define the test task
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

# Add a clean task for removing test artifacts
task :clean do
  # Add any cleanup tasks here if needed
  puts "Clean task completed"
end

# Add a help task
task :help do
  puts "Available tasks:"
  puts "  test    - Run all tests (default)"
  puts "  clean   - Clean up test artifacts"
  puts "  help    - Show this help message"
end
