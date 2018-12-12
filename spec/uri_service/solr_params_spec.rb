require 'rails_helper'

RSpec.describe URIService::SolrParams do
  context 'when creating fq queries' do
    let(:params) { URIService::SolrParams.new }

    it 'solr escapes fq values' do
      params.fq('animals', 'dogs+cats')
      expect(params.to_h).to include(fq: ['animals:"dogs\+cats"'])
    end
  end

  context 'when creating q queries' do
    let(:params) { URIService::SolrParams.new }

    it 'solr escapes q values' do
      params.q('foo-bar')
      expect(params.to_h).to include(q: 'foo\-bar')
    end
  end
end
