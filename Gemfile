source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.3'

gem 'rails', '~> 5.2.1'

# Databases
gem 'sqlite3'
gem 'mysql2'

# Use Puma as the app server
gem 'puma', '~> 3.11'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false
gem 'kaminari', github: 'kaminari/kaminari', branch: 'master' # Can be updated when max_per_page works correctly.
gem 'rsolr'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  gem 'capistrano', '~> 3.11', require: false
  gem 'capistrano-cul', require: false
  gem 'capistrano-passenger', '~> 0.1', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-resque', '~> 0.2.2', require: false
  gem 'capistrano-rvm', '~> 0.1', require: false

  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'coveralls', require: false
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'json_spec'
  gem 'rspec-rails', '~> 3.8'
  gem 'rubocop', '~> 0.60.0', require: false
  gem 'rubocop-rails_config'
  gem 'rubocop-rspec'
  gem 'solr_wrapper', '~> 2.0'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
end
