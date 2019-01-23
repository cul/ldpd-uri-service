require 'rails_helper'

RSpec.describe 'Admin' do
  describe '#commit' do
    it 'returns successful response' do
      post_with_auth '/api/v1/admin/commit'
      expect(response.status).to be 204
    end
  end
end
