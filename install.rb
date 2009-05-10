FileUtils.cp("#{File.dirname(__FILE__)}/example/twitterify.yml","#{RAILS_ROOT}/config")
puts File.read("#{File.dirname(__FILE__)}/README.rdoc")