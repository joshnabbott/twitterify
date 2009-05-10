require 'httparty'
require 'twitterify'
ActiveRecord::Base.instance_eval { include FuKing::Twitterify }
ActiveRecord::Base.instance_eval { include ActionView::Helpers::UrlHelper }