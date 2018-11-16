
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

    desc 'CI build without rubocop'
    task ci_nocop: [:environment, 'uri_service:ci_specs']

    desc 'CI build with Rubocop validation'
    task ci: [:environment, 'uri_service:rubocop', 'uri_service:ci_specs']

    require 'solr_wrapper/rake_task'
    desc 'CI build just running specs'
    task ci_specs: :environment do
      start_time = Time.now

      ENV['RAILS_ENV'] = 'test'
      Rails.env = ENV['RAILS_ENV']

      puts "Unpacking and starting solr...\n"
      SolrWrapper.wrap do |solr_wrapper_instance|
        # Create collection
        solr_wrapper_instance.with_collection(name: 'test', dir: File.join('spec/fixtures', 'solr_cores/uri_service_solr6/conf')) do |collection_name|
          Rake::Task['db:drop'].invoke
          Rake::Task['db:create'].invoke
          Rake::Task['db:migrate'].invoke
          Rake::Task['uri_service:rspec'].invoke
        end
        print 'Stopping solr...'
      end
      puts 'stopped.'

      puts "\nCI run finished in #{(Time.now - start_time)} seconds"
    end

  rescue LoadError => e
    puts '[Warning] Exception creating ci/rubocop/rspec rake tasks.  This message can be ignored in environments that intentionally do not pull in the appropriate gems (i.e. production).'
    puts e
  end

  task :clear_solr do
    uri_service_config = YAML.load(File.open(File.join(Rails.root, 'config', 'uri_service.yml')))[ENV['RAILS_ENV']]
    rsolr = RSolr.connect(url: uri_service_config['solr_url'])
    rsolr.delete_by_query('*:*')
    rsolr.commit
  end
end
