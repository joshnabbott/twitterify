module FuKing
  module Twitterify
    CONFIG_FILE = RAILS_ROOT + '/config/twitterify.yml'
    TWEET_URL   = 'http://twitter.com/statuses/update.xml'

    # Mix below class methods into ActiveRecord.
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end

    # Class methods to mix into active record.
    module ClassMethods # :nodoc:
      def twitterify(*options)
        return if self.included_modules.include?(FuKing::Twitterify::InstanceMethods)
        instance_eval { include FuKing::Twitterify::InstanceMethods }
        # include this so the model has access to it's URL
        instance_eval { include ActionController::UrlWriter }
        validate_attributes(options)
        # if twitterify is called but no options are specified
        # this will at least tweet the url
        options = [:url] if options.empty?
        conditions = parse_conditions_from_options(options)
        # I'm sure there's a more elegant way to do this.
        after_create Proc.new { |record|
          if conditions[:if]
            record.tweet_me(options) if conditions[:if].call(record)
          elsif conditions[:unless]
            record.tweet_me(options) unless conditions[:unless].call(record)
          else
            record.tweet_me(options)
          end
        }
      end
    private
      def parse_conditions_from_options(options)
        conditions = options.extract_options!.symbolize_keys
        conditions.assert_valid_keys(:if, :unless)
        conditions
      end
      def validate_attributes(attributes)
        valid_attributes = self.column_names.push('url')
        attributes.each do |attribute|
          next unless attribute.is_a?(Symbol)
          raise "#{attribute} is not an attribute that can be tweeted. Make sure attribute is one of:\r\n#{valid_attributes.join("\r\n")}. If you would like to pass a string into your status, wrap the string in quotes." unless valid_attributes.include?(attribute.to_s)
        end
      end
    end # ClassMethods

    # Instance methods to mix into ActiveRecord.
    module InstanceMethods #:nodoc:
      def tweet_me(options = nil)
        update(parse_options(options))
      end

    private
      def configs
        if File.exists?(CONFIG_FILE)
          configs = File.open(CONFIG_FILE) { |file| YAML.load(file) }['twitterify']
          configs.symbolize_keys!
        else
          raise ArgumentError, "There is no config file!"
        end
      end

      # Ripped off right the hell from Rails.
      def interpolate_string(string)
        instance_eval("%@#{string.gsub('@', '\@')}@")
      end

      def parse_options(options)
        status_array = options.inject([]) do |array,option|
          array << (send(option) rescue interpolate_string(option))
          array
        end
        status = status_array.join(' - ')
        truncate(status)
      end

      def tweet_params(params)
        options = { :basic_auth => { :username => configs[:username], :password => configs[:password] } }
        options.merge!(params)
        options
      end

      def truncate(text, length = 140, truncate_string = "...")
        if text
          l = length - truncate_string.mb_chars.length
          chars = text.mb_chars
          (chars.length > length ? chars[0...l] + truncate_string : text).to_s
        end
      end

      def update(status, in_reply_to_status_id = nil)
        if configs["#{RAILS_ENV}_uri".to_sym].blank?
          logger.debug("Skipping tweet in RAILS_ENV=#{RAILS_ENV}. To change this, specify a value for #{RAILS_ENV}_uri in config/twitter.yml.")
        else
          response = HTTParty.post(TWEET_URL, tweet_params(:query => {:status => CGI::escapeHTML(status), :in_reply_to_status_id => in_reply_to_status_id}))
          if response.keys.include?('status')
            logger.debug("Tweet success!")
            true
          else response.keys.include?('error')
            logger.debug("Tweet failed: #{response.inspect}")
            raise response.inspect
          end
        end
      end

      # For when someone passes url into the options
      # This should return the url to this object
      def url
        url_for(:host => configs["#{RAILS_ENV}_uri".to_sym],
          :controller => self.class.name.tableize,
          :action => 'show',
          :id => self)
      end
    end # InstanceMethods
  end # Twitterify
end # FuKing