module URIService
  module JSON
    # Converts hash or Term record into output hash used by the api
    #
    # @param [Hash|Term] obj to convert to hash for output
    # @return [Hash]
    def self.term(obj)
      if obj.is_a? Term
        h = obj.as_json(only: [:uuid, :uri, :pref_label, :alt_label, :authority, :term_type])

        if obj.vocabulary
          obj.vocabulary.custom_fields.each { |f, _| h[f] = obj.custom_fields.fetch(f, nil) }
        end

        h
      elsif obj.is_a? Hash
        document = obj.symbolize_keys

        output = {
          uuid:       document.fetch(:uuid, nil),
          uri:        document.fetch(:uri, nil),
          pref_label: document.fetch(:pref_label, nil),
          alt_label:  document.fetch(:alt_label, []),
          authority:  document.fetch(:authority, nil),
          term_type:  document.fetch(:term_type, nil)
        }

        # TODO: Eventually create a Vocabulary lookup cache so we don't do a db query every time we format a Term/Hash as JSON
        if vocabulary = Vocabulary.find_by(string_key: document[:vocabulary])
          extra_fields = ::JSON.parse(document[:custom_fields])
          vocabulary.custom_fields.keys.each do |f|
            output[f] = extra_fields.fetch(f, nil)
          end
        end

        output
      end
    end

    def self.term_search(solr_response)
      start = solr_response['response']['start'].to_i
      per_page = solr_response['responseHeader']['params']['rows'].to_i

      {
        page: current_page(start, per_page),
        per_page: per_page,
        total_records: solr_response['response']['numFound'],
        terms: solr_response['response']['docs'].map { |d| term(d) }
      }
    end

    def self.custom_field(vocabulary, field_key)
      vocabulary.custom_fields[field_key].merge(field_key: field_key)
    end

    # Generates JSON with errors
    #
    # @param String|Array strings describing error
    def self.errors(errors)
      { errors: Array.wrap(errors).map { |e| { title: e } } }
    end

    private

      def self.current_page(start, per_page)
        return 1 if start < 1
        per_page_normalized = per_page < 1 ? 1 : per_page
        (start / per_page_normalized).ceil + 1
      end
  end
end
