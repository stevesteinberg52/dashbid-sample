source 'https://rubygems.org'

ruby "2.3.0"

gem 'rails', '4.2.6' # https://rubygems.org/gems/rails/versions
gem 'mysql2', '0.3.20' # use whatever works on ec2...
gem 'sass-rails', '5.0.4'
gem 'coffee-rails', '4.1.1'

###  JS-runtimes, etc
gem 'therubyracer', '0.12.2', require: 'v8', platforms: :ruby
gem 'uglifier', '2.7.2'
gem 'jquery-rails', '4.1.0' # lazy-ness for sure; use gem rather then including scripts and rake task...
gem 'jquery-tablesorter', '=1.18.2'

gem 'rake', '~> 11.1.1'
gem 'td', '~> 0.11.14'
gem 'railsless-deploy', '1.1.3', require: nil  ### we don't want this loaded, but we need it around..
gem 'bcrypt-ruby', '~> 3.0.0' # To use ActiveModel has_secure_password
gem 'devise', '3.5.4'
gem 'devise_invitable', '1.5.5'
gem 'user_impersonate2', '=0.10.1', require: 'user_impersonate'
gem 'activerecord-import', '0.12.0' # For BULK uploading / db operations
gem 'multi_xml', '=0.5.5' ### xml parsing.  these are already required by other gems.
gem 'nokogiri', '=1.6.6.2'
gem 'twitter-bootstrap-rails', github: 'seyhunak/twitter-bootstrap-rails', branch: 'bootstrap3'
gem 'rickshaw_rails', '=1.4.5' # note this is NOT rickshaw-rails, lol  # https://github.com/logical42/rickshaw_rails
gem 'gitlab', '=3.3.0'
gem 'grit', '=2.5.0' # gem 'gash'
gem 'kaminari', '~>0.16.3'
gem 'redcarpet', '=3.1.1'   # markdown processor
gem 'roo', '=1.12.1'        # reading spreadsheets, etc
gem 'axlsx_rails', '=0.1.5' # writing xlsx, via axlsx gem
gem 'axlsx', git: "https://github.com/randym/axlsx.git", ref: '8babcca0c343490ad4f49c80e4940982c58fca98'
gem 'ransack', '=1.6.3'     # used for searches
gem 'i18n', '0.7.0'
gem 'tooltipster-rails', '=3.2.6' # tooltip
gem 'paper_trail', '4.1.0'
gem "sentry-raven", '0.15.3'
gem 'diffy', '3.1.0'
gem 'dalli', '=2.7.4' # memcached connection
gem 'kgio', '=2.9.3' # not sure if this makes it faster, but this says it does https://github.com/mperham/dalli
gem 'pundit', '1.0.1'
gem 'marginalia', '1.3.0'
      # gem 'carrierwave','=0.10.0' # for file uploads
      # gem 'fog','1.36.0'         # to support Amazon S3
gem 'activerecord-deprecated_finders', require: 'active_record/deprecated_finders'
gem 'nested_form'
gem 'rack-cors', '0.4.0'

    # # sidekiq
    # source "https://dac3c822:6971c9e8@enterprise.contribsys.com/" do #our unique URL for sidekiq enterprise
    #   gem 'sidekiq-ent'
    # end
    # gem 'capistrano-sidekiq', github: 'seuros/capistrano-sidekiq'
    # gem 'sinatra', '>= 1.3.0', require: nil # just for sidekiq dashboard

# NOT TEST
group :development, :production  do
  # Deploy with Capistrano & use it on the server... don't ask
  gem 'capistrano', '=2.15.7'
  gem 'capistrano-unicorn', '0.2.0'
  gem 'rvm-capistrano', '=1.5.6', require: false
      #### gem 'aws-sdk', '=1.33.0'
end

# Production
group :production do
  gem 'unicorn', '=4.8.3' # Use unicorn as the app server
  gem 'unicorn-worker-killer', '0.4.4'
  gem 'newrelic_rpm', '=3.16.2.321'
end

#  NOT production
group :development, :test do
  gem 'quiet_assets', '=1.1.0'
  gem 'mongrel', '>= 1.2.0.pre2' # JCB: WAY better then webrick , but should use thin... or  unicorn with nginx
  gem 'annotate'
  gem 'pry', '0.10.1'
  gem 'rspec-rails'
  gem 'awesome_print', '~> 1.6'
  gem 'factory_girl_rails', '~> 4.5'
  gem 'letter_opener', '1.4.1'
  gem 'rack-mini-profiler'
end

# Test
gem 'test-unit'
group :test do
  gem 'ruby-prof'
  gem 'capybara', '>= 1.1.2'
  gem 'database_cleaner', '=1.4.1'
  gem 'launchy', '=2.4.3'
  gem 'mocha','=1.1.0'
  gem 'simplecov', '~> 0.9', require: false
  gem 'shoulda-matchers', '~> 3.1', require: false
  gem 'timecop', '0.8'
  gem 'vcr', '~> 3.0.1'
  gem 'webmock', '~> 1.22.6'
  gem 'rails-perftest'
end


## fix for "Sprockets method `register_engine` is deprecated"
gem 'sprockets', '3.6.3'