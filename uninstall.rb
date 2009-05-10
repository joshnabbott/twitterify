config_file = "#{RAILS_ROOT}/config/twitterify.yml"
File.delete(config_file) if File.exists?(config_file)