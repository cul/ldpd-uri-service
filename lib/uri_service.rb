module URIService
  thread_mattr_accessor :solr_connection

  def self.solr
    @solr_connection ||= URIService::Solr.new
  end
end
