module URIService
  thread_mattr_accessor :solr_connection

  SOLR_SUFFIX = {
    'string'  => '_si',
    'number'  => '_ii',
    'boolean' => '_bi'
  }.freeze

  # TODO: Write test to make sure only one object is created.
  def self.solr
    self.solr_connection = URIService::Solr.new unless solr_connection
    solr_connection
  end

  def self.solr_suffix(data_type)
    SOLR_SUFFIX[data_type]
  end
end
