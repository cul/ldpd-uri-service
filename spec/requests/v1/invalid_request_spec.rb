require 'rails_helper'

RSpec.describe 'Invalid Requests', type: :request do
  context 'when requesting a format other than json' do
    before do
      get '/api/v1/vocabularies.xml'
    end

    it 'returns 406' do
      expect(response.status).to be 406
    end
  end
end
