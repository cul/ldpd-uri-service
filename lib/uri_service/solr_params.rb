module URIService
  class SolrParams
    attr_reader :parameters

    def initialize
      @parameters = {
        q: nil,
        qt: 'search',
        fq: [],
        rows: URIService::DEFAULT_PER_PAGE,
        start: 0
      }
    end

    def fq(field, value)
      @parameters[:fq] << "#{field}:\"#{escape(value)}\"" unless value.nil? ## should probably escape
      self
    end

    def rows(num)
      @parameters[:rows] = num
      self
    end

    def q(query)
      @parameters[:q] = escape(query) unless query.nil?
      self
    end

    [:vocabulary, :authority, :uri, :pref_label, :alt_labels, :term_type].each do |term_attribute|
      define_method term_attribute do |value|
        fq(term_attribute.to_s, value)
      end
    end

    def pagination(per_page, page)
      @parameters[:start] = (page.to_i - 1) * per_page.to_i
      @parameters[:rows]  = per_page.to_i
      self
    end

    def to_h
      parameters
    end

    private

      # Solr escape values when quering.
      def escape(v)
        URIService.solr.solr_escape(v)
      end
  end
end
