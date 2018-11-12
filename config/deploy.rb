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
)

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
