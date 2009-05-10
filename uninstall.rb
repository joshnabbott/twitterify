config_file = "#{RAILS_ROOT}/config/twitter.yml"
File.rm(config_file) if File.exist?(config_file)