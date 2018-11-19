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
    # @return URIService::Solr::Term if matching term found
    def find_term(vocabulary, uri)
      results = connection.get('select', params: { q: "uri:\"#{uri}\"", fq: "vocabulary:\"#{vocabulary}\"" })
      case results['response']['numFound']
      when 0
        nil
      when 1
        term_document(results['response']['docs'].first)
      else
        raise 'More than one term document matched uri'
      end
    end

    # Search through terms
    def search_term(vocabulary, q)
    end

    # Add document
    #
    # @param Hash json document to be added to solr
    def add(doc)
      connection.add(doc)
      connection.commit # probably need to make this optional or leverage soft commit
    end

    # Deleting term based on uuid (solr primary key)
    #
    # @param String uuid
    def delete(uuid)
      connection.delete_by_query('uuid:' + solr_escape(uuid))
      connection.commit # if commit
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

    def term_document(doc)
      doc.slice('uri', 'term_type', 'authority', 'uuid', 'pref_label', 'alt_label')
         .merge(JSON.parse(doc['custom_fields']))
         .symbolize_keys
    end
  end
end
