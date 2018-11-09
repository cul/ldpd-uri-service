require 'solr_wrapper/rake_task'

namespace :uri_service do
  begin
    # This code is in a begin/rescue block so that the Rakefile is usable
    # in an environment where RSpec is unavailable (i.e. production).

    require 'rspec/core/rake_task'
    RSpec::Core::RakeTask.new(:rspec) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
      spec.pattern += FileList['spec/*_spec.rb']
      spec.rspec_opts = ['--backtrace'] if ENV['CI']
    end

    require 'rubocop/rake_task'
    desc 'Run style checker'
    RuboCop::RakeTask.new(:rubocop) do |task|
      task.requires << 'rubocop-rspec'
      task.fail_on_error = true
    end

  rescue LoadError => e
    puts '[Warning] Exception creating rspec rake tasks.  This message can be ignored in environments that intentionally do not pull in the RSpec gem (i.e. production).'
    puts e
  end

  desc 'CI build without rubocop'
  task ci_nocop: [:environment, 'uri_service:ci_task'] do
  end

  desc 'CI build with Rubocop validation'
  task ci: [:environment, 'uri_service:rubocop', 'uri_service:ci_task'] do
  end

  desc 'CI setup and run'
  task ci_task: [:environment] do
    start_time = Time.now

    ENV['RAILS_ENV'] = 'test'
    Rails.env = ENV['RAILS_ENV']

    Rake::Task['uri_service:ci_solrwrapper'].invoke

    puts "\n" + 'CI run finished in ' + (Time.now - start_time).to_s + ' seconds'
  end

  task ci_solrwrapper: :environment do
    puts "Unpacking and starting solr...\n"
    solr_version = '6.3.0'
    SolrWrapper.wrap(
      port: 9983,
      version: solr_version,
      verbose: false,
      managed: true,
      solr_zip_path: File.join('tmp', "solr-#{solr_version}.zip"),
      instance_dir: File.join('tmp', "solr-#{solr_version}"),
    ) do |solr_wrapper_instance|
      # Create collection
      solr_wrapper_instance.with_collection(name: 'uri_service_test', dir: File.join('spec/fixtures', 'solr_cores/uri_service_solr6/conf')) do |collection_name|
        Rake::Task['uri_service:ci_impl'].invoke
      end
      puts 'Stopping solr...'
    end
    puts 'Solr has been stopped.'
  end

  task :ci_impl do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:seed'].invoke
    Rake::Task['uri_service:rspec'].invoke
  end

  task :clear_solr do
    uri_service_config = YAML.load(File.open(File.join(Rails.root, 'config', 'uri_service.yml')))[ENV['RAILS_ENV']]
    rsolr = RSolr.connect(url: uri_service_config['solr_url'])
    rsolr.delete_by_query('*:*')
    rsolr.commit
  end
end
