source :rubygems

#gemspec

gem "riak-client"
gem "activemodel", ">= 3.0.0"
gem "activesupport", ">= 3.0.0"
gem "tzinfo"

group :development, :test do
  gem "rake"
  gem "ammeter"
end

group :guard do
  gem 'guard-rspec'
  gem 'rb-fsevent'
  gem 'growl'
end

if File.directory?(File.expand_path("../../riak-client", __FILE__))
  gem 'riak-client', :path => "../riak-client"
end

platforms :jruby do
 gem 'jruby-openssl'
end
