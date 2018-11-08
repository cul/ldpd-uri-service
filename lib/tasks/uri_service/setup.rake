namespace :uri_service do
  namespace :setup do
    # Note: Don't include Rails environment for this task, since enviroment includes a check for the presence of database.yml
    task :config_files do
      # Set up files
      default_development_port = 8983
      default_test_port = 9983

      # database.yml
      database_yml_file = File.join(Rails.root, 'config/database.yml')
      FileUtils.touch(database_yml_file) # Create if it doesn't exist
      database_yml = YAML.load_file(database_yml_file) || {}
      ['development', 'test'].each do |env_name|
        database_yml[env_name] = {
          'adapter' => 'sqlite3',
          'database' => 'db/' + env_name + '.sqlite3',
          'pool' => 5,
          'timeout' => 5000
        }
      end
      File.open(database_yml_file, 'w') { |f| f.write database_yml.to_yaml }

      # uri_service.yml
      uri_service_yml_file = File.join(Rails.root, 'config/uri_service.yml')
      FileUtils.touch(uri_service_yml_file) # Create if it doesn't exist
      uri_service_yml = YAML.load_file(uri_service_yml_file) || {}
      ['development', 'test'].each do |env_name|
        uri_service_yml[env_name] = {
          'local_uri_base' => 'http://id.library.columbia.edu/term/',
          'temporary_uri_base' => 'temp:',
          'solr' => {
            'url' => 'http://localhost:' + (env_name == 'test' ? default_test_port : default_development_port).to_s + '/solr/uri_service_' + env_name
          }
        }
      end
      File.open(uri_service_yml_file, 'w') { |f| f.write uri_service_yml.to_yaml }
    end
  end
end
