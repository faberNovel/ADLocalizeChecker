source 'https://rubygems.org'

ruby '2.6.5'

gem 'cocoapods', '1.10.1'
gem 'CFPropertyList', '3.0.2'
gem 'fastlane'
gem 'aws-sdk-s3', '1.13.0'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
