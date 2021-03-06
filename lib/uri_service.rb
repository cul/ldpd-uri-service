module URIService
  thread_mattr_accessor :solr_connection

  SOLR_SUFFIX = {
    'string'  => '_si',
    'integer' => '_ii',
    'boolean' => '_bi'
  }.freeze

  DEFAULT_LIMIT = 20
  MAX_LIMIT     = 500

  def self.solr
    self.solr_connection = URIService::Solr.new unless solr_connection
    solr_connection
  end

  def self.solr_suffix(data_type)
    SOLR_SUFFIX[data_type]
  end

  def self.api_keys
    URI_SERVICE_CONFIG.fetch('api_keys', [])
  end

  def self.local_uri_host
    if host = URI_SERVICE_CONFIG['local_uri_host']
      host.ends_with?('/') ? host : "#{host}/"
    else
      raise 'Missing local_uri_host in config/uri_service.yml'
    end
  end

  def self.commit_after_save?
    URI_SERVICE_CONFIG.fetch('commit_after_save', false)
  end
end
