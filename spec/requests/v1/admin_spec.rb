require 'rails_helper'

RSpec.describe 'Admin' do
  describe '#commit' do
    include_examples 'authentication required', 'post', '/api/v1/admin/commit'

    it 'returns successful response' do
      post_with_auth '/api/v1/admin/commit'
      expect(response.status).to be 204
    end
  end
end
