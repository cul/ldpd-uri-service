require 'rails_helper'

RSpec.describe URIService do
  describe '.solr' do
    subject(:solr_connection) { URIService.solr }

    it 'uses the same instance of URIService::Solr' do
      expect(solr_connection).to be URIService.solr
      expect(solr_connection).to be URIService.solr_connection
    end
  end
end
