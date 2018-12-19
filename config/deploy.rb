# config valid for current version and patch releases of Capistrano
lock '~> 3.11.0'

set :instance, 'ldpd'
set :application, 'uri_service'
set :deploy_name, "#{fetch(:application)}_#{fetch(:stage)}"

# used to run rake db:migrate, etc
# Default value for :rails_env is fetch(:stage)
set :rails_env, fetch(:deploy_name)
# use the rvm wrapper
set :rvm_ruby_version, fetch(:deploy_name)

set :repo_url,  'git@github.com:cul/ldpd-uri-service.git'

set :remote_user, "#{fetch(:instance)}serv"

# Default deploy_to directory is /var/www/:application
set :deploy_to,   "/opt/passenger/#{fetch(:instance)}/#{fetch(:deploy_name)}"

# Default value for :format is :airbrussh
# set :format, :airbrussh

# Default value for :log_level is :debug
set :log_level, :info

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log')

# Default value for keep_releases is 5
set :keep_releases, 3

set :passenger_restart_with_touch, true

set :linked_files, fetch(:linked_files, []).push(
  'config/database.yml',
  'config/solr.yml',
  'config/secrets.yml',
  'config/uri_service.yml'
)
