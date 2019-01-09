namespace :uri_service do
  namespace :setup do
    # Note: Don't include Rails environment for this task, since enviroment includes a check for the presence of database.yml
    desc 'Generates configuration files'
    task :config_files do
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

      # solr.yml
      solr_yml_file = File.join(Rails.root, 'config/solr.yml')
      FileUtils.touch(solr_yml_file) # Create if it doesn't exist
      solr_yml = YAML.load_file(solr_yml_file) || {}
      ['development', 'test'].each do |env_name|
        solr_yml[env_name] = {
          'url' => 'http://localhost:9983/solr/' + env_name
        }
      end
      File.open(solr_yml_file, 'w') { |f| f.write solr_yml.to_yaml }

      # uri_service.yml
      uri_service_file = File.join(Rails.root, 'config/uri_service.yml')
      FileUtils.touch(uri_service_file) # Create if it doesn't exist
      uri_service_yml = YAML.load_file(uri_service_file) || {}
      uri_service_yml = {
        'development' => { 'local_uri_host' => 'localhost:3000', 'api_keys' => ['firstdevkey'], 'commit_after_save' => false },
        'test' => { 'local_uri_host' => 'https://example.com', 'api_keys' => ['firsttestkey'], 'commit_after_save' => true }
      }

      File.open(uri_service_file, 'w') { |f| f.write uri_service_yml.to_yaml }
    end
  end
end
