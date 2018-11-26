module URIService
  class SolrParams
    DEFAULT_ROWS = 25

    attr_reader :parameters

    def initialize
      @parameters = {
        q: '*:*',
        qt: 'search',
        fq: [],
        rows: DEFAULT_ROWS,
        start: 0
      }
    end

    def fq(field, value)
      @parameters[:fq] << "#{field}:\"#{value}\"" unless value.nil? ## should probably escape
      self
    end

    def rows(num)
      @parameters[:rows] = num
      self
    end

    def q(query)
      @parameters[:q] = q unless query.nil?
      self
    end

    [:vocabulary, :authority, :uri, :pref_label, :alt_label, :term_type].each do |term_attribute|
      define_method term_attribute do |value|
        fq(term_attribute.to_s, value)
      end
    end

    def to_h
      parameters
    end
  end
end
