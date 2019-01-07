module URIService
  class Solr
    attr_accessor :connection

    # Returns configuration options set in solr.yml
    def connection_config
      Rails.application.config_for(:solr).symbolize_keys
    end

    # Returns RSolr connection to Solr instance
    def connection
      @connection ||= RSolr.connect(connection_config)
    end

    # Look up term
    #
    # @param String vocabulary vocabulary string key
    # @param String uri
    # @return nil if no matching term found
    # @return Hash if matching term found
    def find_term(vocabulary, uri)
      results = search do |params|
        params.vocabulary(vocabulary).uri(uri)
      end

      case results['response']['numFound']
      when 0
        nil
      when 1
        results['response']['docs'].first
      else
        raise 'More than one term document matched uri'
      end
    end

    # Solr query. Returns solr json.
    def search
      search_parameters = SolrParams.new

      yield(search_parameters)

      params = search_parameters.to_h

      # If making a search use the /search handler otherwise use /select. /select
      # queries with just filters are faster than /search queries.
      handler = (params[:q].blank?) ? 'select' : 'search'

      connection.get(handler, params: params)
    end

    # Add document
    #
    # @param Hash json document to be added to solr
    def add(doc)
      connection.add(doc)
      connection.commit unless URIService.auto_commit?
    end

    # Deleting term based on uuid (solr primary key)
    #
    # @param String uuid
    def delete(uuid)
      connection.delete_by_query('uuid:' + solr_escape(uuid))
      connection.commit unless URIService.auto_commit?
    end

    # Wrapper around escape method for different versions of RSolr
    def solr_escape(str)
      if RSolr.respond_to?(:solr_escape)
        RSolr.solr_escape(str) # Newer method
      else
        RSolr.escape(str) # Fall back to older method
      end
    end

    def clear_solr_index
      connection.delete_by_query('*:*')
      connection.commit
    end
  end
end
