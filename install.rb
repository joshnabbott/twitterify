File.copy("#{File.dirname(__FILE__)}/example/twitterify.yml","#{RAILS_ROOT}/config/twitterify.yml")
puts File.read("#{File.dirname(__FILE__)}/README.rdoc")