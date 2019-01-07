require 'rails_helper'

RSpec.describe 'OpenAPI Specification', type: :request do
  context '/api/v1/open_api_specification' do
    before do
      get_with_auth '/api/v1/open_api_specification'
    end

    it 'returns OpenAPI specification' do
      expect(response.body).to be_json_eql('"2.0"').at_path('swagger')
      expect(response.body).to be_json_eql('"/api/v1"').at_path('basePath')
      expect(response.body).to be_json_eql('"URI Service API"').at_path('info/title')
    end
  end
end
