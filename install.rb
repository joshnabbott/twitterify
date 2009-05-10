require 'fileutils'
FileUtils.cp("#{File.dirname(__FILE__)}/example/twitterify.yml","#{RAILS_ROOT}/config/twitterify.yml")
puts FileUtils.read("#{File.dirname(__FILE__)}/README")